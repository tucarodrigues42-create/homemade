require "test_helper"

class UsuariosControllerTest < ActionDispatch::IntegrationTest
  test "admin cadastra usuário" do
    entrar_como usuarios(:admin)
    get new_usuario_url
    assert_response :success
    assert_difference("Usuario.count") do
      post usuarios_url, params: { usuario: { email: "nova@homemade.com", password: "segredo1", password_confirmation: "segredo1" } }
    end
    assert_redirected_to usuarios_url
    assert_not Usuario.last.adm?
  end

  test "equipe não cadastra nem remove usuários" do
    entrar_como usuarios(:equipe)
    get new_usuario_url
    assert_redirected_to usuarios_url
    assert_no_difference("Usuario.count") do
      post usuarios_url, params: { usuario: { email: "x@homemade.com", password: "segredo1", password_confirmation: "segredo1" } }
    end
    assert_no_difference("Usuario.count") { delete usuario_url(usuarios(:admin)) }
  end

  test "equipe edita a própria conta, mas não a dos outros" do
    entrar_como usuarios(:equipe)
    get edit_usuario_url(usuarios(:equipe))
    assert_response :success
    patch usuario_url(usuarios(:equipe)), params: { usuario: { email: "equipe@homemade.com", password: "", password_confirmation: "" } }
    assert_redirected_to usuario_url(usuarios(:equipe))
    get edit_usuario_url(usuarios(:admin))
    assert_redirected_to usuarios_url
  end

  test "equipe não consegue se tornar administradora" do
    entrar_como usuarios(:equipe)
    patch usuario_url(usuarios(:equipe)), params: { usuario: { adm: "1" } }
    assert_not usuarios(:equipe).reload.adm?
  end

  test "admin troca a senha" do
    entrar_como usuarios(:admin)
    patch usuario_url(usuarios(:admin)), params: { usuario: { password: "novasenha", password_confirmation: "novasenha" } }
    assert usuarios(:admin).reload.authenticate("novasenha")
  end

  test "admin remove outro usuário, mas não a si mesmo" do
    entrar_como usuarios(:admin)
    assert_difference("Usuario.count", -1) { delete usuario_url(usuarios(:equipe)) }
    assert_no_difference("Usuario.count") { delete usuario_url(usuarios(:admin)) }
  end

  test "lista e mostra" do
    entrar_como usuarios(:equipe)
    get usuarios_url
    assert_response :success
    get usuario_url(usuarios(:admin))
    assert_response :success
  end
end
