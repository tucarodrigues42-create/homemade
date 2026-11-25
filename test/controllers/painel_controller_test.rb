require "test_helper"

class PainelControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "início mostra o painel com os números do dia" do
    get root_url
    assert_response :success
    assert_select ".numero-destaque .numero-valor", "2" # pedidos de hoje, sem o cancelado
    assert_select ".producao-mini li", 3
    assert_select ".numero", 4
    assert_select ".semana li", 7
    assert_match "panetones", response.body
  end

  test "mostra compromissos dos próximos dias" do
    get root_url
    assert_select "#titulo-proximos"
    assert_match "Bolo de Natal 1kg para João", response.body
  end

  test "avisa produto vencido e ingrediente que acabou" do
    produtos(:bolo).update_columns(vencimento: Date.current - 2)
    ingredientes(:chocolate).update_columns(quantidade: 0)
    get root_url
    assert_select ".alerta-erro", /Bolo de Natal 1kg está vencido/
    assert_select ".alerta-aviso", /Chocolate meio amargo acabou/
  end

  test "sem alertas mostra tudo certo" do
    get root_url
    assert_select ".tudo-certo"
  end

  test "tela Mais tem atalhos e botão de sair" do
    get mais_url
    assert_response :success
    assert_select "a[href='#{enderecos_path}']"
    assert_select "a[href='#{agendas_path}']"
    assert_select "a[href='#{produtos_path}']"
    assert_select "a[href='#{ingredientes_path}']"
    assert_select "form[action='#{sessions_path}']"
  end

  test "painel pede login" do
    delete sessions_url
    get root_url
    assert_redirected_to login_url
  end
end
