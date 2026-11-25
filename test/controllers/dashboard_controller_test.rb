require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "pede login" do
    delete sessions_url
    get dashboard_url
    assert_redirected_to login_url
  end

  test "mostra faturamento sem os cancelados" do
    get dashboard_url
    assert_response :success
    # hoje: Maria 199,70 (a receber) + João 59,90 (pago) = 259,60; o cancelado de 80,00 fica de fora
    assert_select ".numero", text: /Hoje\s+R\$ 259,60/
    assert_select ".grafico-coluna", 14
    assert_select ".ranking li", 3
    assert_select ".ranking li:first-child .ranking-nome", "Brigadeiro gourmet"
  end

  test "agrupa por semanas e meses" do
    get dashboard_url(ver: "semanas")
    assert_select ".grafico-coluna", 12
    get dashboard_url(ver: "meses")
    assert_select ".grafico-coluna", 12
    get dashboard_url(ver: "qualquer")
    assert_select ".grafico-coluna", 14
  end

  test "aparece no menu Mais" do
    get mais_url
    assert_select "a[href='#{dashboard_path}']"
  end
end
