require "test_helper"

class IngredientesControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "lista, mostra e abre formulários" do
    get ingredientes_url
    assert_response :success
    get ingrediente_url(ingredientes(:chocolate))
    assert_response :success
    get new_ingrediente_url(produto_id: produtos(:bolo).id)
    assert_response :success
    assert_select "option[selected][value='#{produtos(:bolo).id}']"
    get edit_ingrediente_url(ingredientes(:chocolate))
    assert_response :success
  end

  test "cria ingrediente" do
    assert_difference("Ingrediente.count") do
      post ingredientes_url, params: { ingrediente: { nome: "Leite condensado", descricao: "Caixa com 12", preco: "60",
                                                      quantidade: 2, vencimento: Date.current + 60, produto_id: produtos(:bolo).id } }
    end
    assert_redirected_to produto_url(produtos(:bolo))
  end

  test "mostra erro sem produto" do
    post ingredientes_url, params: { ingrediente: { nome: "Açúcar", descricao: "1kg", preco: 5, quantidade: 1, vencimento: Date.current } }
    assert_response :unprocessable_entity
  end

  test "atualiza e exclui" do
    patch ingrediente_url(ingredientes(:chocolate)), params: { ingrediente: { quantidade: 7 } }
    assert_redirected_to ingrediente_url(ingredientes(:chocolate))
    assert_difference("Ingrediente.count", -1) { delete ingrediente_url(ingredientes(:chocolate)) }
    assert_redirected_to ingredientes_url
  end
end
