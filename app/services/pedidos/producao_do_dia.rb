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

    def itens
      PedidoItem.joins(:pedido).merge(pedidos)
    end

    # Itens ligados ao cadastro de produtos: agrupa pelo produto, com o nome atual.
    def linhas_de_produtos
      com_produto = itens.where.not(produto_id: nil)
      quantidades = com_produto.group(:produto_id).sum(:quantidade)
      contagem = com_produto.group(:produto_id).distinct.count(:pedido_id)
      nomes = Produto.where(id: quantidades.keys).pluck(:id, :nome).to_h
      nomes_copiados = com_produto.group(:produto_id).maximum(:nome)
      quantidades.map do |produto_id, qtd|
        Linha.new(produto_id: produto_id, nome: nomes[produto_id] || nomes_copiados[produto_id],
                  quantidade: qtd.to_i, pedidos: contagem[produto_id].to_i)
      end
    end

    # Itens escritos à mão (sem produto cadastrado): agrupa pelo nome, sem diferenciar maiúsculas.
    def linhas_avulsas
      chave = Arel.sql("LOWER(TRIM(pedido_itens.nome))")
      avulsos = itens.where(produto_id: nil)
      quantidades = avulsos.group(chave).sum(:quantidade)
      contagem = avulsos.group(chave).distinct.count(:pedido_id)
      nomes = avulsos.group(chave).minimum(:nome)
      quantidades.map do |nome, qtd|
        Linha.new(produto_id: nil, nome: nomes[nome].to_s.strip, quantidade: qtd.to_i, pedidos: contagem[nome].to_i)
      end
    end
  end
end
