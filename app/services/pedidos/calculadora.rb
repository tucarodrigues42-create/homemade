module Pedidos
  # Calcula os valores do pedido a partir dos itens. Não sabe nada de tela nem de banco.
  # (Ideia adaptada do Orders::Calculator do projeto Alon's Bakery OMS, licença MIT.)
  class Calculadora
    def initialize(pedido)
      @pedido = pedido
    end

    def subtotal
      @pedido.subtotal
    end

    def total
      valor = subtotal + @pedido.taxa_entrega.to_d - @pedido.desconto.to_d
      valor.negative? ? 0.to_d : valor.round(2)
    end
  end
end
