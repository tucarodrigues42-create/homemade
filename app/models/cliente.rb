class Cliente < ApplicationRecord
  belongs_to :endereco, optional: true
  has_many :pedidos, dependent: :nullify
  # Cidade e estado já vêm preenchidos (Arapiraca – AL); sem rua, número e bairro o
  # cliente é tratado como "retira na loja" e nenhum endereço é criado.
  accepts_nested_attributes_for :endereco, reject_if: :sem_endereco?

  def sem_endereco?(atributos)
    atributos["id"].blank? && atributos.values_at("rua", "numero", "bairro", "cep", "complemento").all?(&:blank?)
  end

  before_validation :limpar_telefones

  validates :nome, presence: true, length: { minimum: 3, maximum: 80 }
  validates :celular, presence: true, length: { in: 10..11 }, numericality: { only_integer: true }
  validates :telefone, length: { in: 10..11 }, numericality: { only_integer: true }, allow_blank: true
  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_associated :endereco

  scope :em_ordem, -> { order(:nome) }

  # Link que abre a conversa do cliente no WhatsApp (DDI 55 do Brasil).
  def whatsapp_url
    "https://wa.me/55#{celular}" if celular.present?
  end

  def celular_formatado
    formatar(celular)
  end

  def telefone_formatado
    formatar(telefone)
  end

  private

  def limpar_telefones
    self.celular = celular.to_s.gsub(/\D/, "").sub(/\A55(?=\d{10,11}\z)/, "") if celular
    self.telefone = telefone.to_s.gsub(/\D/, "") if telefone
  end

  def formatar(numero)
    return "" if numero.blank?
    case numero.length
    when 11 then "(#{numero[0, 2]}) #{numero[2, 5]}-#{numero[7, 4]}"
    when 10 then "(#{numero[0, 2]}) #{numero[2, 4]}-#{numero[6, 4]}"
    else numero
    end
  end
end
