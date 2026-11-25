module Pedidos
  # Números de faturamento a partir dos pedidos (cancelados nunca entram).
  # O dia que conta é a data do pedido (dia da entrega ou retirada).
  class Faturamento
    Periodo = Struct.new(:inicio, :fim, :rotulo, :rotulo_longo, :recebido, :a_receber, :pedidos, keyword_init: true) do
      def total = recebido + a_receber
    end
    Resumo = Struct.new(:recebido, :a_receber, :pedidos, keyword_init: true) do
      def total = recebido + a_receber
      def ticket_medio = pedidos.zero? ? 0.to_d : (total / pedidos).round(2)
    end
    Produto = Struct.new(:nome, :quantidade, :valor, keyword_init: true)

    VISOES = {
      "dias" => { quantidade: 14, nome: "Últimos 14 dias" },
      "semanas" => { quantidade: 12, nome: "Últimas 12 semanas" },
      "meses" => { quantidade: 12, nome: "Últimos 12 meses" }
    }.freeze

    attr_reader :visao, :hoje

    def initialize(visao: "dias", hoje: Date.current)
      @visao = VISOES.key?(visao) ? visao : "dias"
      @hoje = hoje
    end

    def self.resumo(intervalo)
      linhas = Pedido.ativos.where(data: intervalo).group(:pagamento).pluck(:pagamento, Arel.sql("SUM(total)"), Arel.sql("COUNT(*)"))
      recebido = linhas.select { |p, _, _| p == "pago" }.sum { |_, v, _| v.to_d }
      a_receber = linhas.reject { |p, _, _| p == "pago" }.sum { |_, v, _| v.to_d }
      Resumo.new(recebido: recebido, a_receber: a_receber, pedidos: linhas.sum { |_, _, c| c.to_i })
    end

    def periodos
      @periodos ||= begin
        lista = inicios.map { |ini| Periodo.new(inicio: ini, fim: fim_de(ini), recebido: 0.to_d, a_receber: 0.to_d, pedidos: 0, **rotulos(ini)) }
        pedidos_no_intervalo.each do |data, pagamento, total|
          periodo = lista.reverse_each.find { |p| data >= p.inicio }
          next unless periodo && data <= periodo.fim
          pagamento == "pago" ? periodo.recebido += total.to_d : periodo.a_receber += total.to_d
          periodo.pedidos += 1
        end
        lista
      end
    end

    def intervalo
      periodos.first.inicio..periodos.last.fim
    end

    def resumo_do_grafico
      Resumo.new(recebido: periodos.sum(&:recebido), a_receber: periodos.sum(&:a_receber), pedidos: periodos.sum(&:pedidos))
    end

    def maior_total
      periodos.map(&:total).max.to_d
    end

    # Produtos que mais vendem no período do gráfico, pela quantidade.
    def mais_vendidos(limite = 8)
      itens = PedidoItem.joins(:pedido).merge(Pedido.ativos.where(data: intervalo)).pluck(:produto_id, :nome, :quantidade, :preco_unitario)
      nomes_atuais = ::Produto.where(id: itens.map(&:first).compact.uniq).pluck(:id, :nome).to_h
      agrupado = Hash.new { |h, k| h[k] = Produto.new(nome: nil, quantidade: 0, valor: 0.to_d) }
      itens.each do |produto_id, nome, qtd, preco|
        chave = produto_id ? "p#{produto_id}" : "n#{nome.to_s.strip.downcase}"
        linha = agrupado[chave]
        linha.nome ||= nomes_atuais[produto_id] || nome.to_s.strip
        linha.quantidade += qtd.to_i
        linha.valor += preco.to_d * qtd.to_i
      end
      agrupado.values.sort_by { |p| [-p.quantidade, -p.valor, p.nome.downcase] }.first(limite)
    end

    private

    def quantidade = VISOES[@visao][:quantidade]

    def inicios
      case @visao
      when "dias" then (0...quantidade).map { |i| hoje - (quantidade - 1 - i) }
      when "semanas" then (0...quantidade).map { |i| hoje.beginning_of_week - (quantidade - 1 - i).weeks }
      when "meses" then (0...quantidade).map { |i| hoje.beginning_of_month << (quantidade - 1 - i) }
      end
    end

    def fim_de(inicio)
      case @visao
      when "dias" then inicio
      when "semanas" then inicio.end_of_week
      when "meses" then inicio.end_of_month
      end
    end

    def rotulos(inicio)
      case @visao
      when "dias"
        { rotulo: inicio.strftime("%d/%m"), rotulo_longo: I18n.l(inicio, format: "%A, %d/%m").capitalize }
      when "semanas"
        { rotulo: inicio.strftime("%d/%m"), rotulo_longo: "Semana de #{inicio.strftime('%d/%m')} a #{inicio.end_of_week.strftime('%d/%m')}" }
      when "meses"
        { rotulo: I18n.l(inicio, format: "%b").delete(".").capitalize, rotulo_longo: I18n.l(inicio, format: "%B de %Y").capitalize }
      end
    end

    def pedidos_no_intervalo
      Pedido.ativos.where(data: inicios.first..fim_de(inicios.last)).pluck(:data, :pagamento, :total)
    end
  end
end
