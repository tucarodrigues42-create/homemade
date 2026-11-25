# Uma linha do pedido. O nome e o preço do produto são copiados no momento do
# pedido: se o preço mudar depois, os pedidos antigos continuam com o valor combinado.
class PedidoItem < ApplicationRecord
  self.table_name = "pedido_itens"

  belongs_to :pedido, inverse_of: :itens
  belongs_to :produto, optional: true

  before_validation :copiar_do_produto

  validates :nome, presence: true, length: { maximum: 120 }
  validates :quantidade, numericality: { only_integer: true, greater_than: 0, less_than: 10_000 }
  validates :preco_unitario, numericality: { greater_than_or_equal_to: 0 }

  def subtotal
    preco_unitario.to_d * quantidade.to_i
  end

  private

  def copiar_do_produto
    return unless produto
    self.nome = produto.nome if nome.blank? || produto_id_changed?
    self.preco_unitario = produto.preco if preco_unitario.blank? || (produto_id_changed? && preco_unitario.to_d.zero?)
  ensure
    self.preco_unitario ||= 0
    self.quantidade ||= 1
  end
end
