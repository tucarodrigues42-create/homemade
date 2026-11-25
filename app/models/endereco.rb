class Endereco < ApplicationRecord
  has_many :clientes, dependent: :nullify

  before_validation :limpar_cep

  validates :rua, :numero, :bairro, :cidade, :estado, presence: true
  validates :cep, length: { is: 8 }, numericality: { only_integer: true }, allow_blank: true

  scope :em_ordem, -> { order(:bairro, :rua) }

  def resumo
    linha = "#{rua}, #{numero}"
    linha += " – #{bairro}" if bairro.present?
    linha += " (#{complemento})" if complemento.present?
    linha
  end

  def cep_formatado
    cep.to_s.length == 8 ? "#{cep[0, 5]}-#{cep[5, 3]}" : cep.to_s
  end

  private

  def limpar_cep
    self.cep = cep.to_s.gsub(/\D/, "").presence if cep
  end
end
