class CreatePedidos < ActiveRecord::Migration[7.2]
  def change
    create_table :pedidos do |t|
      t.references :cliente, foreign_key: { on_delete: :nullify }
      t.string :nome_cliente, null: false
      t.string :whatsapp
      t.string :tipo_entrega, null: false, default: "retirada"
      t.text :endereco_entrega
      t.date :data, null: false
      t.time :horario
      t.string :status, null: false, default: "novo"
      t.string :pagamento, null: false, default: "pendente"
      t.string :forma_pagamento
      t.decimal :taxa_entrega, precision: 10, scale: 2, null: false, default: 0
      t.decimal :desconto, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.text :descricao
      t.timestamps
    end
    add_index :pedidos, :data
    add_index :pedidos, :status

    create_table :pedido_itens do |t|
      t.references :pedido, null: false, foreign_key: { on_delete: :cascade }
      t.references :produto, foreign_key: { on_delete: :nullify }
      t.string :nome, null: false
      t.integer :quantidade, null: false, default: 1
      t.decimal :preco_unitario, precision: 10, scale: 2, null: false, default: 0
      t.string :observacao
      t.timestamps
    end
  end
end
