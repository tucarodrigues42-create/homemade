require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "pede login para acessar o sistema" do
    get agendas_url
    assert_redirected_to login_url
  end

  test "tela de login mostra a marca Homemade" do
    get login_url
    assert_response :success
    assert_select "img[alt='Homemade Confeitaria']"
    assert_select "title", /Homemade Confeitaria/
  end

  test "entra com e-mail e senha corretos" do
    entrar_como usuarios(:admin)
    assert_redirected_to root_url
    follow_redirect!
    assert_select "nav.menu"
  end

  test "não entra com senha errada" do
    entrar_como usuarios(:admin), senha: "errada"
    assert_response :unprocessable_entity
    assert_select ".aviso-erro", /incorretos/
  end

  test "sai do sistema" do
    entrar_como usuarios(:admin)
    delete sessions_url
    assert_redirected_to login_url
    get agendas_url
    assert_redirected_to login_url
  end
end
