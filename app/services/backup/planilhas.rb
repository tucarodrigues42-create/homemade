require "csv"

module Backup
  # Planilhas (CSV) de clientes, pedidos e itens. Abrem no Excel, no Google
  # Planilhas e no Numbers. Usam ";" e vírgula nos valores, como as planilhas
  # em português esperam, e começam com a marca UTF-8 para os acentos saírem certos.
  class Planilhas
    BOM = "﻿".freeze
    OPCOES = { col_sep: ";", force_quotes: false }.freeze

    def initialize(de: nil, ate: nil)
      @de = de
      @ate = ate
    end

    def clientes
      totais = Pedido.ativos.where.not(cliente_id: nil).group(:cliente_id)
                     .pluck(:cliente_id, Arel.sql("COUNT(*)"), Arel.sql("COALESCE(SUM(total), 0)"), Arel.sql("MAX(data)"))
                     .to_h { |id, qtd, soma, ultimo| [id, [qtd, soma, ultimo]] }
      gerar(["Nº", "Nome", "WhatsApp", "Telefone", "E-mail", "Endereço", "Bairro", "Cidade", "CEP",
             "Pedidos", "Total em pedidos", "Último pedido", "Cadastrado em"]) do |csv|
        Cliente.includes(:endereco).order(:nome).each do |c|
          qtd, soma, ultimo = totais.fetch(c.id, [0, 0, nil])
          e = c.endereco
          csv << [c.id, c.nome, c.celular_formatado, c.telefone_formatado, c.email,
                  e && "#{e.rua}, #{e.numero}#{" (#{e.complemento})" if e.complemento.present?}",
                  e&.bairro, e && "#{e.cidade} – #{e.estado}", e&.cep_formatado,
                  qtd, dinheiro(soma), data(ultimo), data(c.created_at)]
        end
      end
    end

    def pedidos
      gerar(["Nº", "Data", "Horário", "Cliente", "WhatsApp", "Entrega ou retirada", "Endereço de entrega",
             "Etapa", "Pagamento", "Forma de pagamento", "Itens", "Quantidade de itens", "Subtotal",
             "Taxa de entrega", "Desconto", "Total", "Descrição", "Fotos", "Criado em"]) do |csv|
        escopo.includes(:itens).each do |p|
          csv << [p.id, data(p.data), hora(p.horario), p.nome_cliente, p.whatsapp_formatado, p.tipo_entrega_nome,
                  (p.endereco_entrega if p.entrega?), p.status_nome, (p.pago? ? "Pago" : "A receber"),
                  p.forma_pagamento_nome, p.itens.map { |i| "#{i.quantidade}x #{i.nome}#{" (#{i.observacao})" if i.observacao.present?}" }.join(" | "),
                  p.quantidade_total, dinheiro(p.subtotal), dinheiro(p.taxa_entrega), dinheiro(p.desconto),
                  dinheiro(p.total), p.descricao, p.fotos_count, data_hora(p.created_at)]
        end
      end
    end

    # Uma linha por item: bom para somar a produção numa planilha.
    def itens
      gerar(["Pedido Nº", "Data", "Horário", "Cliente", "Etapa", "Quantidade", "Item", "Observação",
             "Preço unitário", "Subtotal"]) do |csv|
        escopo.includes(:itens).each do |p|
          p.itens.each do |i|
            csv << [p.id, data(p.data), hora(p.horario), p.nome_cliente, p.status_nome, i.quantidade, i.nome,
                    i.observacao, dinheiro(i.preco_unitario), dinheiro(i.subtotal)]
          end
        end
      end
    end

    # Evita que um texto começando com "=" vire fórmula ao abrir a planilha.
    Linhas = Struct.new(:csv) do
      def <<(linha)
        csv << linha.map { |v| v.is_a?(String) && v.match?(/\A[=+@]/) ? "'#{v}" : v }
      end
    end

    private

    def escopo
      pedidos = Pedido.order(:data, :horario, :id)
      pedidos = pedidos.where(data: @de..) if @de
      pedidos = pedidos.where(data: ..@ate) if @ate
      pedidos
    end

    def gerar(cabecalho)
      BOM + CSV.generate(**OPCOES) do |csv|
        csv << cabecalho
        yield(Linhas.new(csv))
      end
    end

    def dinheiro(valor) = format("%.2f", valor.to_d).tr(".", ",")
    def data(valor)
      valor = Date.parse(valor) if valor.is_a?(String)
      valor&.strftime("%d/%m/%Y")
    end
    def hora(valor) = valor&.strftime("%H:%M")
    def data_hora(valor) = valor&.in_time_zone&.strftime("%d/%m/%Y %H:%M")
  end
end
