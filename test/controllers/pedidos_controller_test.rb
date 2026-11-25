require "test_helper"

class PedidosControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "exige login" do
    delete sessions_url
    get pedidos_url
    assert_redirected_to login_url
  end

  test "lista os próximos pedidos" do
    get pedidos_url
    assert_response :success
    assert_select ".pedido", 4
  end

  test "filtra por dia, entrega e pagamento" do
    get pedidos_url(periodo: "dia", dia: Date.current)
    assert_select ".pedido", 3
    get pedidos_url(periodo: "dia", dia: Date.current, tipo: "entrega")
    assert_select ".pedido", 1
    get pedidos_url(periodo: "proximos", pagamento: "pago")
    assert_select ".pedido", 1
    get pedidos_url(periodo: "proximos", status: "abertos")
    assert_select ".pedido", 3
  end

  test "busca pedidos" do
    get pedidos_url(periodo: "todos", q: "ninho")
    assert_select ".pedido", 1
    assert_match "Ana Lúcia", response.body
  end

  test "mostra a produção do dia" do
    get producao_url(dia: Date.current)
    assert_response :success
    assert_select ".tabela-producao tbody tr", 3
    assert_select ".tabela-producao tfoot td strong", "29"
  end

  test "abre o formulário de novo pedido" do
    get new_pedido_url(cliente_id: clientes(:maria).id)
    assert_response :success
    assert_select "input[name='pedido[nome_cliente]'][value=?]", "Maria das Graças"
    assert_select "template#modelo-item"
  end

  test "cria pedido com itens" do
    assert_difference(["Pedido.count", "PedidoItem.count"], 1) do
      post pedidos_url, params: { pedido: {
        nome_cliente: "Carla Souza", whatsapp: "(82) 99111-2222", tipo_entrega: "retirada",
        data: Date.current + 2, horario: "16:00", pagamento: "pendente", status: "novo",
        taxa_entrega: "0", desconto: "0",
        itens_attributes: { "0" => { produto_id: produtos(:bolo).id, quantidade: "2", preco_unitario: "" },
                            "1" => { produto_id: "", nome: "", quantidade: "1" } }
      } }
    end
    pedido = Pedido.order(:id).last
    assert_redirected_to pedido_url(pedido)
    assert_equal BigDecimal("160"), pedido.total
  end

  test "não cria pedido sem nome" do
    assert_no_difference("Pedido.count") do
      post pedidos_url, params: { pedido: { nome_cliente: "", data: Date.current, descricao: "x", tipo_entrega: "retirada" } }
    end
    assert_response :unprocessable_entity
  end

  test "mostra o pedido com link do WhatsApp" do
    get pedido_url(pedidos(:maria_hoje))
    assert_response :success
    assert_select "a.botao-whatsapp[href^=?]", "https://wa.me/5582999990000?text="
  end

  test "edita e remove item" do
    pedido = pedidos(:maria_hoje)
    patch pedido_url(pedido), params: { pedido: { itens_attributes: {
      "0" => { id: pedido_itens(:maria_bolo).id, _destroy: "1" }
    } } }
    assert_redirected_to pedido_url(pedido)
    assert_equal 1, pedido.reload.itens.count
    assert_equal BigDecimal("119.80"), pedido.total
  end

  test "avança a etapa" do
    patch status_pedido_url(pedidos(:maria_hoje), status: "em_producao")
    assert_equal "em_producao", pedidos(:maria_hoje).reload.status
  end

  test "não pula etapa inválida" do
    patch status_pedido_url(pedidos(:maria_hoje), status: "entregue")
    assert_equal "novo", pedidos(:maria_hoje).reload.status
    assert flash[:alert].present?
  end

  test "marca como pago e volta" do
    patch pagamento_pedido_url(pedidos(:maria_hoje))
    assert pedidos(:maria_hoje).reload.pago?
    patch pagamento_pedido_url(pedidos(:maria_hoje))
    assert_not pedidos(:maria_hoje).reload.pago?
  end

  test "exclui pedido e seus itens" do
    assert_difference("PedidoItem.count", -2) do
      delete pedido_url(pedidos(:maria_hoje))
    end
    assert_redirected_to pedidos_url
  end
end
