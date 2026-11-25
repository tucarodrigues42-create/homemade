class Agenda < ApplicationRecord
  validates :mensagem, presence: true

  # Compromissos com data aparecem primeiro, do mais próximo ao mais distante.
  scope :em_ordem, -> { order(Arel.sql("data IS NULL, data ASC, horario IS NULL, horario ASC, created_at DESC")) }
  scope :do_dia, ->(dia) { where(data: dia) }
end
