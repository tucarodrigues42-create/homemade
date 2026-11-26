module Backup
  # Cópia completa dos dados (clientes, endereços, pedidos com itens, produtos,
  # ingredientes e agenda) num arquivo .json, para guardar no celular, no
  # computador ou no Google Drive e restaurar quando precisar.
  #
  # Restaurar NUNCA apaga nada: cada registro do arquivo é gravado com o mesmo
  # número que tinha. Se já existir, é atualizado com a versão do backup; se não
  # existir (ex.: foi apagado sem querer), volta a existir. O que foi criado
  # depois do backup continua lá.
  #
  # Usuários e senhas não entram (por segurança). As fotos dos pedidos também não
  # entram, porque deixariam o arquivo pesado demais; elas continuam no sistema.
  class Completo
    VERSAO = 1
    MODELOS = {
      "enderecos" => "Endereco",
      "clientes" => "Cliente",
      "produtos" => "Produto",
      "ingredientes" => "Ingrediente",
      "agendas" => "Agenda",
      "pedidos" => "Pedido",
      "pedido_itens" => "PedidoItem"
    }.freeze
    # Contador calculado pelo próprio sistema: não é copiado nem sobrescrito.
    IGNORAR = { "pedidos" => %w[fotos_count] }.freeze
    NOMES = {
      "enderecos" => "endereços", "clientes" => "clientes", "produtos" => "produtos",
      "ingredientes" => "ingredientes", "agendas" => "compromissos", "pedidos" => "pedidos",
      "pedido_itens" => "itens de pedido"
    }.freeze

    class ArquivoInvalido < StandardError; end

    def self.gerar
      tabelas = MODELOS.to_h do |tabela, nome|
        modelo = nome.constantize
        colunas = modelo.column_names - IGNORAR.fetch(tabela, [])
        linhas = modelo.unscoped.order(:id).pluck(*colunas).map { |valores| colunas.zip(valores).to_h }
        [tabela, linhas.map { |linha| linha.transform_values { |v| serializar(v) } }]
      end
      {
        "sistema" => "Homemade Confeitaria",
        "versao" => VERSAO,
        "gerado_em" => Time.current.iso8601,
        "totais" => tabelas.transform_values(&:size),
        "tabelas" => tabelas
      }
    end

    def self.serializar(valor)
      case valor
      when BigDecimal then valor.to_s("F")
      when Date then valor.iso8601
      # Grava exatamente como fica no banco (UTC), para voltar igual ao restaurar.
      # Horário (coluna "time") vem com a data 01/01/2000: guarda só HH:MM:SS.
      when Time, ActiveSupport::TimeWithZone
        utc = valor.utc
        utc.year == 2000 && utc.month == 1 && utc.day == 1 ? utc.strftime("%H:%M:%S") : utc.strftime("%Y-%m-%d %H:%M:%S.%6N")
      else valor
      end
    end

    # Lê o texto do arquivo e grava tudo. Devolve quantos registros de cada tipo.
    def self.restaurar(texto)
      dados = JSON.parse(texto)
      unless dados.is_a?(Hash) && dados["tabelas"].is_a?(Hash) && dados["versao"].to_i.between?(1, VERSAO)
        raise ArquivoInvalido, "Este arquivo não é um backup do sistema Homemade."
      end

      resultado = {}
      ActiveRecord::Base.transaction do
        MODELOS.each do |tabela, nome|
          linhas = Array(dados["tabelas"][tabela])
          next if linhas.empty?
          modelo = nome.constantize
          colunas = modelo.column_names - IGNORAR.fetch(tabela, [])
          agora = Time.current
          registros = linhas.map do |linha|
            raise ArquivoInvalido, "Arquivo com dados estragados em #{NOMES[tabela]}." unless linha.is_a?(Hash) && linha["id"].present?
            registro = linha.slice(*colunas)
            registro["created_at"] ||= agora if colunas.include?("created_at")
            registro["updated_at"] ||= agora if colunas.include?("updated_at")
            colunas.index_with { |c| registro[c] }
          end
          registros.each_slice(500) { |lote| modelo.upsert_all(lote, unique_by: :id, record_timestamps: false) }
          resultado[tabela] = registros.size
        end
      end
      ajustar_sequencias
      resultado
    rescue JSON::ParserError
      raise ArquivoInvalido, "Não consegui ler o arquivo. Escolha o arquivo .json baixado em Backup."
    end

    # No PostgreSQL, os próximos números (de pedido, cliente...) continuam depois do maior restaurado.
    def self.ajustar_sequencias
      conexao = ActiveRecord::Base.connection
      return unless conexao.respond_to?(:reset_pk_sequence!)
      MODELOS.keys.each { |tabela| conexao.reset_pk_sequence!(tabela) }
    end

    def self.resumo(resultado)
      partes = MODELOS.keys.filter_map { |t| "#{resultado[t]} #{NOMES[t]}" if resultado[t].to_i.positive? }
      partes.empty? ? "O arquivo não tinha dados." : partes.to_sentence
    end
  end
end
