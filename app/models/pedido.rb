# Pedido (encomenda) de um cliente.
#
# A ideia de congelar o preço de cada item no momento do pedido, de calcular o
# total num objeto separado e de controlar as etapas do pedido com uma tabela de
# transições permitidas foi adaptada do projeto "Alon's Bakery OMS"
# (https://github.com/Artumax9/alons-bakery-oms, licença MIT, © 2026 Arturo Paredes).
class Pedido < ApplicationRecord
  STATUS = {
    "novo" => "Novo",
    "confirmado" => "Confirmado",
    "em_producao" => "Em produção",
    "pronto" => "Pronto",
    "entregue" => "Entregue",
    "cancelado" => "Cancelado"
  }.freeze

  # Para onde cada etapa pode ir. Dá para voltar uma etapa, caso alguém toque errado.
  TRANSICOES = {
    "novo" => %w[confirmado em_producao cancelado],
    "confirmado" => %w[em_producao novo cancelado],
    "em_producao" => %w[pronto confirmado cancelado],
    "pronto" => %w[entregue em_producao cancelado],
    "entregue" => %w[pronto],
    "cancelado" => %w[novo]
  }.freeze

  TIPOS_ENTREGA = { "retirada" => "Retirada na loja", "entrega" => "Entrega" }.freeze
  PAGAMENTOS = { "pendente" => "Pendente", "pago" => "Pago" }.freeze
  FORMAS_PAGAMENTO = { "pix" => "Pix", "dinheiro" => "Dinheiro", "cartao" => "Cartão", "transferencia" => "Transferência" }.freeze

  belongs_to :cliente, optional: true
  has_many :itens, -> { order(:id) }, class_name: "PedidoItem", inverse_of: :pedido, dependent: :destroy
  accepts_nested_attributes_for :itens, allow_destroy: true, reject_if: :item_em_branco?

  before_validation :limpar_whatsapp
  before_validation :preencher_do_cliente
  before_save :calcular_total

  validates :nome_cliente, presence: true, length: { maximum: 80 }
  validates :data, presence: true
  validates :whatsapp, length: { in: 10..11 }, numericality: { only_integer: true }, allow_blank: true
  validates :tipo_entrega, inclusion: { in: TIPOS_ENTREGA.keys }
  validates :status, inclusion: { in: STATUS.keys }
  validates :pagamento, inclusion: { in: PAGAMENTOS.keys }
  validates :forma_pagamento, inclusion: { in: FORMAS_PAGAMENTO.keys }, allow_blank: true
  validates :taxa_entrega, :desconto, numericality: { greater_than_or_equal_to: 0 }
  validates :endereco_entrega, presence: { message: "é obrigatório para entrega" }, if: :entrega?
  validate :precisa_de_item_ou_descricao

  scope :do_dia, ->(dia) { where(data: dia) }
  scope :ativos, -> { where.not(status: "cancelado") }
  scope :em_aberto, -> { where.not(status: %w[entregue cancelado]) }
  scope :em_ordem, -> { order(:data, Arel.sql("horario IS NULL"), :horario, :id) }

  def self.buscar(termo)
    return all if termo.blank?
    texto = "%#{sanitize_sql_like(termo.strip.downcase)}%"
    digitos = termo.gsub(/\D/, "")
    condicao = "LOWER(nome_cliente) LIKE :texto OR LOWER(COALESCE(descricao, '')) LIKE :texto " \
               "OR EXISTS (SELECT 1 FROM pedido_itens i WHERE i.pedido_id = pedidos.id AND LOWER(i.nome) LIKE :texto)"
    condicao += " OR whatsapp LIKE :digitos" if digitos.length >= 4
    condicao += " OR pedidos.id = :id" if termo.strip.match?(/\A#?\d+\z/)
    where(condicao, texto: texto, digitos: "%#{digitos}%", id: termo.delete("#").to_i)
  end

  def entrega? = tipo_entrega == "entrega"
  def pago? = pagamento == "pago"
  def cancelado? = status == "cancelado"

  def status_nome = STATUS.fetch(status, status)
  def tipo_entrega_nome = TIPOS_ENTREGA.fetch(tipo_entrega, tipo_entrega)
  def forma_pagamento_nome = FORMAS_PAGAMENTO[forma_pagamento]

  def proximos_status = TRANSICOES.fetch(status, [])

  # Muda a etapa respeitando a tabela de transições.
  def mudar_status!(novo)
    novo = novo.to_s
    unless proximos_status.include?(novo)
      errors.add(:status, "não pode ir de #{status_nome} para #{STATUS.fetch(novo, novo)}")
      return false
    end
    update(status: novo)
  end

  def subtotal
    itens.reject(&:marked_for_destruction?).sum(&:subtotal)
  end

  def quantidade_total
    itens.reject(&:marked_for_destruction?).sum { |i| i.quantidade.to_i }
  end

  def whatsapp_url
    "https://wa.me/55#{whatsapp}" if whatsapp.present?
  end

  def whatsapp_formatado
    return "" if whatsapp.blank?
    whatsapp.length == 11 ? "(#{whatsapp[0, 2]}) #{whatsapp[2, 5]}-#{whatsapp[7, 4]}" : "(#{whatsapp[0, 2]}) #{whatsapp[2, 4]}-#{whatsapp[6, 4]}"
  end

  def numero = "##{id}"

  private

  def item_em_branco?(atributos)
    atributos["id"].blank? && atributos["produto_id"].blank? && atributos["nome"].blank?
  end

  def limpar_whatsapp
    self.whatsapp = whatsapp.to_s.gsub(/\D/, "").sub(/\A55(?=\d{10,11}\z)/, "").presence if whatsapp
  end

  # Ao escolher um cliente cadastrado, completa o que ficou em branco.
  def preencher_do_cliente
    return unless cliente
    self.nome_cliente = cliente.nome if nome_cliente.blank?
    self.whatsapp = cliente.celular if whatsapp.blank?
    self.endereco_entrega = cliente.endereco&.resumo if entrega? && endereco_entrega.blank?
  end

  def calcular_total
    self.total = Pedidos::Calculadora.new(self).total
  end

  def precisa_de_item_ou_descricao
    return if itens.reject(&:marked_for_destruction?).any? || descricao.present?
    errors.add(:base, "Adicione pelo menos um item ou escreva a descrição do pedido")
  end
end
