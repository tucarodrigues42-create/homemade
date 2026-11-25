module Pedidos
  # Soma, produto por produto, tudo o que precisa ser produzido para os pedidos
  # de um dia (pedidos cancelados ficam de fora). A soma é feita no banco, com
  # números inteiros, para a contagem ser exata.
  class ProducaoDoDia
    Linha = Struct.new(:produto_id, :nome, :quantidade, :pedidos, keyword_init: true)

    def initialize(dia, incluir_entregues: true)
      @dia = dia
      @incluir_entregues = incluir_entregues
    end

    def pedidos
      escopo = Pedido.ativos.do_dia(@dia)
      escopo = escopo.where.not(status: "entregue") unless @incluir_entregues
      escopo
    end

    def linhas
      @linhas ||= (linhas_de_produtos + linhas_avulsas).sort_by { |l| [-l.quantidade, l.nome.downcase] }
    end

    def total_unidades
      linhas.sum(&:quantidade)
    end

    private

    # Uma consulta só traz as linhas dos itens; a soma é feita aqui com inteiros (exata).
    def itens
      @itens ||= PedidoItem.joins(:pedido).merge(pedidos).pluck(:produto_id, :nome, :quantidade, :pedido_id)
    end

    # Itens ligados ao cadastro de produtos: agrupa pelo produto, com o nome atual.
    def linhas_de_produtos
      com_produto = itens.select(&:first)
      nomes = Produto.where(id: com_produto.map(&:first).uniq).pluck(:id, :nome).to_h
      com_produto.group_by(&:first).map do |produto_id, linhas|
        Linha.new(produto_id: produto_id, nome: nomes[produto_id] || linhas.map { |l| l[1] }.max,
                  quantidade: linhas.sum { |l| l[2].to_i }, pedidos: linhas.map(&:last).uniq.size)
      end
    end

    # Itens escritos à mão (sem produto cadastrado): agrupa pelo nome, sem diferenciar maiúsculas.
    def linhas_avulsas
      itens.reject(&:first).group_by { |l| l[1].to_s.strip.downcase }.map do |_chave, linhas|
        Linha.new(produto_id: nil, nome: linhas.map { |l| l[1].to_s.strip }.min,
                  quantidade: linhas.sum { |l| l[2].to_i }, pedidos: linhas.map(&:last).uniq.size)
      end
    end
  end
end
