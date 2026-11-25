require "test_helper"

class ClientesControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "lista e busca clientes" do
    get clientes_url
    assert_response :success
    assert_select ".item", 2
    get clientes_url(busca: "maria")
    assert_select ".item", 1
    get clientes_url(busca: "98888")
    assert_select ".item", 1
    assert_match "João Pereira", response.body
  end

  test "formulário novo já vem com Arapiraca – AL" do
    get new_cliente_url
    assert_response :success
    assert_select "input[name='cliente[endereco_attributes][cidade]'][value='Arapiraca']"
  end

  test "cria cliente com endereço de entrega" do
    assert_difference(["Cliente.count", "Endereco.count"]) do
      post clientes_url, params: { cliente: {
        nome: "Ana Lúcia", celular: "(82) 99123-4567",
        endereco_attributes: { rua: "Rua Nova", numero: "10", bairro: "Centro", cidade: "Arapiraca", estado: "AL", cep: "57300-000" }
      } }
    end
    cliente = Cliente.last
    assert_redirected_to cliente_url(cliente)
    assert_equal "82991234567", cliente.celular
    assert_equal "57300000", cliente.endereco.cep
  end

  test "cria cliente que só retira, sem endereço" do
    assert_difference("Cliente.count") do
      assert_no_difference("Endereco.count") do
        post clientes_url, params: { cliente: {
          nome: "Carla Souza", celular: "82 98765-4321",
          endereco_attributes: { rua: "", numero: "", bairro: "", cidade: "Arapiraca", estado: "AL", cep: "" }
        } }
      end
    end
    assert_nil Cliente.last.endereco
  end

  test "não cria cliente sem WhatsApp" do
    assert_no_difference("Cliente.count") do
      post clientes_url, params: { cliente: { nome: "Sem Telefone", celular: "" } }
    end
    assert_response :unprocessable_entity
    assert_select ".erros", /WhatsApp/
  end

  test "mostra cliente com link do WhatsApp" do
    get cliente_url(clientes(:maria))
    assert_response :success
    assert_select "a[href='https://wa.me/5582999990000']"
  end

  test "edita e atualiza cliente" do
    get edit_cliente_url(clientes(:joao))
    assert_response :success
    patch cliente_url(clientes(:maria)), params: { cliente: { nome: "Maria das Graças Silva" } }
    assert_redirected_to cliente_url(clientes(:maria))
    assert_equal "Maria das Graças Silva", clientes(:maria).reload.nome
  end

  test "exclui cliente" do
    assert_difference("Cliente.count", -1) { delete cliente_url(clientes(:maria)) }
    assert_redirected_to clientes_url
  end
end
