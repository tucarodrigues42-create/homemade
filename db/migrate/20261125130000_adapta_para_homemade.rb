# Ajustes feitos ao adaptar o sistema da Doceria Dona Torta para a Homemade Confeitaria.
class AdaptaParaHomemade < ActiveRecord::Migration[7.2]
  def change
    # A agenda passa a ter data e horário, para organizar entregas e encomendas.
    add_column :agendas, :data, :date
    add_column :agendas, :horario, :time
    add_index :agendas, :data

    # O CEP vira texto para não perder zeros e aceitar o formato 57300-000.
    change_column :enderecos, :cep, :string

    # Cliente pode ser cadastrado só com nome e WhatsApp (ex.: quem retira na loja).
    change_column_null :clientes, :endereco_id, true

    # A senha padrão do administrador deve ser trocada no primeiro acesso.
    change_column_default :usuarios, :adm, from: nil, to: false
  end
end
