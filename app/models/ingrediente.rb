class Ingrediente < ApplicationRecord
  belongs_to :produto

  validates :nome, presence: true, length: { minimum: 2, maximum: 60 }
  validates :descricao, presence: true
  validates :preco, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantidade, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :vencimento, presence: true

  scope :em_ordem, -> { order(:nome) }

  def vencido?
    vencimento.present? && vencimento < Date.current
  end
end
