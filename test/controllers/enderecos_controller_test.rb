require "test_helper"

class EnderecosControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "lista, mostra e abre formulários" do
    get enderecos_url
    assert_response :success
    get endereco_url(enderecos(:centro))
    assert_response :success
    get new_endereco_url
    assert_response :success
    get edit_endereco_url(enderecos(:centro))
    assert_response :success
  end

  test "cria endereço" do
    assert_difference("Endereco.count") do
      post enderecos_url, params: { endereco: { rua: "Rua A", numero: "1", bairro: "Centro", cidade: "Arapiraca", estado: "AL" } }
    end
    assert_redirected_to endereco_url(Endereco.last)
  end

  test "atualiza endereço" do
    patch endereco_url(enderecos(:centro)), params: { endereco: { bairro: "Centro Histórico" } }
    assert_redirected_to endereco_url(enderecos(:centro))
  end

  test "exclui endereço e mantém o cliente" do
    assert_difference("Endereco.count", -1) do
      assert_no_difference("Cliente.count") { delete endereco_url(enderecos(:centro)) }
    end
    assert_nil clientes(:maria).reload.endereco
  end
end
