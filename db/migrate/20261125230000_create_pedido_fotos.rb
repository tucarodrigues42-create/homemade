# Fotos anexadas ao pedido (referência do bolo, decoração, print da conversa...).
# Ficam guardadas no próprio banco de dados: a hospedagem (Vercel) não tem disco
# permanente, e assim as fotos ficam junto com os pedidos, sem outro serviço.
# O celular reduz cada foto antes de enviar (cerca de 200 a 400 KB).
class CreatePedidoFotos < ActiveRecord::Migration[7.2]
  def change
    create_table :pedido_fotos do |t|
      t.references :pedido, null: false, foreign_key: { on_delete: :cascade }
      t.string :nome
      t.string :content_type, null: false
      t.integer :tamanho, null: false, default: 0
      t.binary :dados, null: false, limit: 16.megabytes
      t.timestamps
    end
    add_column :pedidos, :fotos_count, :integer, null: false, default: 0
  end
end
