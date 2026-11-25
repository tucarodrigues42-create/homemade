class Produto < ApplicationRecord
  has_many :ingredientes, dependent: :destroy
  has_many :pedido_itens, class_name: "PedidoItem", dependent: :nullify

  validates :nome, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 60 }
  validates :descricao, presence: true
  validates :fabricacao, :vencimento, presence: true
  validates :quantidade, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :preco, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :vencimento_depois_da_fabricacao

  scope :em_ordem, -> { order(:nome) }

  def vencido?
    vencimento.present? && vencimento < Date.current
  end

  private

  def vencimento_depois_da_fabricacao
    return if fabricacao.blank? || vencimento.blank?
    errors.add(:vencimento, "deve ser depois da fabricação") if vencimento < fabricacao
  end
end
