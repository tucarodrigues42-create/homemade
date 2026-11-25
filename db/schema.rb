# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_11_25_140000) do
  create_table "agendas", force: :cascade do |t|
    t.text "mensagem"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "data"
    t.time "horario"
    t.index ["data"], name: "index_agendas_on_data"
  end

  create_table "clientes", force: :cascade do |t|
    t.string "nome"
    t.string "telefone"
    t.string "celular"
    t.string "email"
    t.integer "endereco_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endereco_id"], name: "index_clientes_on_endereco_id"
  end

  create_table "enderecos", force: :cascade do |t|
    t.string "rua"
    t.string "numero"
    t.string "bairro"
    t.string "cidade"
    t.string "cep"
    t.string "estado"
    t.string "complemento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ingredientes", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.decimal "preco"
    t.integer "quantidade"
    t.date "vencimento"
    t.integer "produto_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produto_id"], name: "index_ingredientes_on_produto_id"
  end

  create_table "pedido_itens", force: :cascade do |t|
    t.integer "pedido_id", null: false
    t.integer "produto_id"
    t.string "nome", null: false
    t.integer "quantidade", default: 1, null: false
    t.decimal "preco_unitario", precision: 10, scale: 2, default: "0.0", null: false
    t.string "observacao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pedido_id"], name: "index_pedido_itens_on_pedido_id"
    t.index ["produto_id"], name: "index_pedido_itens_on_produto_id"
  end

  create_table "pedidos", force: :cascade do |t|
    t.integer "cliente_id"
    t.string "nome_cliente", null: false
    t.string "whatsapp"
    t.string "tipo_entrega", default: "retirada", null: false
    t.text "endereco_entrega"
    t.date "data", null: false
    t.time "horario"
    t.string "status", default: "novo", null: false
    t.string "pagamento", default: "pendente", null: false
    t.string "forma_pagamento"
    t.decimal "taxa_entrega", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "desconto", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.text "descricao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliente_id"], name: "index_pedidos_on_cliente_id"
    t.index ["data"], name: "index_pedidos_on_data"
    t.index ["status"], name: "index_pedidos_on_status"
  end

  create_table "produtos", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.date "fabricacao"
    t.date "vencimento"
    t.integer "quantidade"
    t.decimal "preco"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "adm", default: false
  end

  add_foreign_key "clientes", "enderecos"
  add_foreign_key "ingredientes", "produtos"
  add_foreign_key "pedido_itens", "pedidos", on_delete: :cascade
  add_foreign_key "pedido_itens", "produtos", on_delete: :nullify
  add_foreign_key "pedidos", "clientes", on_delete: :nullify
end
