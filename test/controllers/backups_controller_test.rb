require "test_helper"

class BackupsControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:admin) }

  def linhas_csv
    CSV.parse(response.body.delete_prefix("﻿"), col_sep: ";")
  end

  test "mostra a tela de backup" do
    get backup_url
    assert_response :success
    assert_select "a[href=?]", backup_completo_path
    assert_select "form[action=?]", backup_restaurar_path
  end

  test "baixa clientes em CSV" do
    get backup_clientes_url
    assert_equal "text/csv", response.media_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert response.body.start_with?("﻿")
    linhas = linhas_csv
    assert_equal "Nome", linhas.first[1]
    assert_equal Cliente.count + 1, linhas.size
    assert(linhas.any? { |l| l[1] == clientes(:maria).nome })
  end

  test "baixa pedidos e itens em CSV, com filtro de período" do
    get backup_pedidos_url
    assert_equal Pedido.count + 1, linhas_csv.size
    get backup_pedidos_url(de: Date.current, ate: Date.current)
    assert_equal Pedido.where(data: Date.current).count + 1, linhas_csv.size
    get backup_itens_url
    assert_equal PedidoItem.count + 1, linhas_csv.size
    assert_match(/\d+,\d{2}/, response.body)
  end

  test "backup completo e restauração devolvem o que foi apagado" do
    get backup_completo_url
    dados = JSON.parse(response.body)
    assert_equal Pedido.count, dados["tabelas"]["pedidos"].size
    arquivo_json = response.body

    pedido = pedidos(:maria_hoje)
    itens = pedido.itens.count
    horario = pedido.horario.strftime("%H:%M")
    total = pedido.total
    pedido.destroy
    clientes(:joao).update_columns(nome: "Nome errado")

    arquivo = Rack::Test::UploadedFile.new(StringIO.new(arquivo_json), "application/json", original_filename: "backup.json")
    post backup_restaurar_url, params: { arquivo: arquivo }
    assert_redirected_to backup_url
    assert_match "restaurado", flash[:notice]

    volta = Pedido.find(pedido.id)
    assert_equal itens, volta.itens.count
    assert_equal horario, volta.horario.strftime("%H:%M")
    assert_equal total, volta.total
    assert_equal "João Pereira", clientes(:joao).reload.nome
  end

  test "restaurar não apaga o que foi criado depois do backup" do
    get backup_completo_url
    arquivo_json = response.body
    novo = Pedido.create!(nome_cliente: "Depois do backup", data: Date.current, descricao: "x")
    post backup_restaurar_url, params: { arquivo: Rack::Test::UploadedFile.new(StringIO.new(arquivo_json), "application/json", original_filename: "b.json") }
    assert Pedido.exists?(novo.id)
  end

  test "recusa arquivo que não é backup" do
    arquivo = Rack::Test::UploadedFile.new(StringIO.new("{\"oi\":1}"), "application/json", original_filename: "x.json")
    assert_no_difference("Pedido.count") { post backup_restaurar_url, params: { arquivo: arquivo } }
    assert_match "não é um backup", flash[:alert]
  end

  test "só o administrador restaura" do
    delete sessions_url
    entrar_como usuarios(:equipe)
    get backup_url
    assert_response :success
    assert_select "form[action=?]", backup_restaurar_path, 0
    post backup_restaurar_url
    assert_match "administrador", flash[:alert]
  end
end
