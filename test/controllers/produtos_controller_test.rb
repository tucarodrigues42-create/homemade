require "test_helper"

class ProdutosControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "lista e mostra produtos" do
    get produtos_url
    assert_response :success
    assert_match "R$ 59,90", response.body
    get produto_url(produtos(:panetone))
    assert_response :success
    assert_match "Chocolate meio amargo", response.body
  end

  test "cria produto e segue para os ingredientes" do
    assert_difference("Produto.count") do
      post produtos_url, params: { produto: { nome: "Rabanada", descricao: "Caixa com 6", fabricacao: Date.current,
                                              vencimento: Date.current + 3, quantidade: 5, preco: "25.00" } }
    end
    assert_redirected_to new_ingrediente_url(produto_id: Produto.last.id)
  end

  test "não aceita validade antes da fabricação" do
    assert_no_difference("Produto.count") do
      post produtos_url, params: { produto: { nome: "Torta", descricao: "x", fabricacao: Date.current,
                                              vencimento: Date.current - 1, quantidade: 1, preco: 10 } }
    end
    assert_response :unprocessable_entity
  end

  test "edita, atualiza e exclui" do
    get edit_produto_url(produtos(:bolo))
    assert_response :success
    patch produto_url(produtos(:bolo)), params: { produto: { quantidade: 8 } }
    assert_redirected_to produto_url(produtos(:bolo))
    assert_difference(["Produto.count", "Ingrediente.count"], -1) { delete produto_url(produtos(:panetone)) }
    assert_redirected_to produtos_url
  end
end
