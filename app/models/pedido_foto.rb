# Foto de referência anexada a um pedido. A imagem fica no banco (coluna "dados").
class PedidoFoto < ApplicationRecord
  self.table_name = "pedido_fotos"

  TAMANHO_MAXIMO = 8.megabytes
  TIPOS = %w[image/jpeg image/png image/webp image/gif image/heic image/heif].freeze

  belongs_to :pedido, counter_cache: :fotos_count

  validates :content_type, inclusion: { in: TIPOS, message: "precisa ser uma foto (JPG, PNG, WEBP ou HEIC)" }
  validates :dados, presence: true
  validates :tamanho, numericality: { less_than_or_equal_to: TAMANHO_MAXIMO, message: "passa de 8 MB" }

  # Lista as fotos sem carregar a imagem em si (que é pesada).
  scope :sem_dados, -> { select(column_names - ["dados"]) }

  def self.do_arquivo(arquivo)
    conteudo = arquivo.read
    new(nome: File.basename(arquivo.original_filename.to_s).first(120),
        content_type: arquivo.content_type.to_s.downcase,
        tamanho: conteudo.bytesize,
        dados: conteudo)
  end
end
