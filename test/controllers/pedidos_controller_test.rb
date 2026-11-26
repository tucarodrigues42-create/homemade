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

  test "recusa etapa inválida" do
    patch status_pedido_url(pedidos(:maria_hoje), status: "inventada")
    assert_equal "novo", pedidos(:maria_hoje).reload.status
    assert flash[:alert].present?
  end

  test "oferece desfazer depois de mudar a etapa" do
    pedido = pedidos(:maria_hoje)
    patch status_pedido_url(pedido, status: "confirmado"), headers: { "HTTP_REFERER" => pedidos_url }
    follow_redirect!
    assert_select ".aviso-desfazer", "Desfazer"
    assert_select "form[action=?]", status_pedido_path(pedido, status: "novo")
  end

  test "cartão tem o botão de escolher a etapa e o de pagamento" do
    pedido = pedidos(:maria_hoje)
    get pedidos_url(periodo: "dia", dia: Date.current)
    assert_select ".pedido-novo .escolher-status-botao", text: /Novo/
    # Ao tocar, aparecem todas as 6 etapas para escolher (a atual fica marcada)
    assert_select ".pedido-novo .opcao-status", 6
    assert_select ".pedido-novo .opcao-status-atual", 1
    assert_select "form[action=?]", status_pedido_path(pedido, status: "pronto")
    assert_select ".botao-pagar", minimum: 1
  end

  test "tela do pedido mostra as 5 etapas" do
    get pedido_url(pedidos(:maria_hoje))
    assert_select ".linha-etapa", 5
    assert_select ".linha-etapa-atual", 1
    assert_select ".segmento", 2
  end

  test "define o pagamento direto" do
    patch pagamento_pedido_url(pedidos(:maria_hoje), valor: "pago")
    patch pagamento_pedido_url(pedidos(:maria_hoje), valor: "pago")
    assert pedidos(:maria_hoje).reload.pago?
  end

  test "anexa, mostra e apaga fotos" do
    pedido = pedidos(:maria_hoje)
    foto = fixture_file_upload("bolo.png", "image/png")
    assert_difference("PedidoFoto.count", 1) do
      post pedido_fotos_url(pedido), params: { fotos: [foto] }
    end
    assert_redirected_to pedido_url(pedido)
    nova = pedido.fotos.last
    get pedido_foto_url(pedido, nova)
    assert_equal "image/png", response.media_type
    assert_equal File.binread(file_fixture("bolo.png")), response.body
    get pedido_url(pedido)
    assert_select ".galeria-item", 1
    assert_difference("PedidoFoto.count", -1) { delete pedido_foto_url(pedido, nova) }
    assert_equal 0, pedido.reload.fotos_count
  end

  test "salva fotos junto com o pedido novo" do
    assert_difference("PedidoFoto.count", 1) do
      post pedidos_url, params: { pedido: { nome_cliente: "Rita", data: Date.current, descricao: "Bolo da foto",
                                            novas_fotos: [fixture_file_upload("bolo.png", "image/png")] } }
    end
    assert_equal 1, Pedido.last.fotos_count
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

  test "lista longa mostra aos poucos, com totais de todos" do
    45.times { |i| Pedido.create!(nome_cliente: "Cliente #{i}", data: Date.current + 3, descricao: "x", total: 10) }
    get pedidos_url(periodo: "proximos")
    assert_select ".pedido", PedidosController::POR_PAGINA
    assert_select ".resumo-lista strong", "49 pedidos"
    assert_select ".carregar-mais a[href*='limite=80']"
    get pedidos_url(periodo: "proximos", limite: 80)
    assert_select ".pedido", 49
    assert_select ".carregar-mais", 0
  end

  test "carrega o Turbo para a navegação rápida" do
    get pedidos_url
    assert_select "script[type=module][src*=turbo]"
    assert_select "meta[name=turbo-refresh-method][content=morph]"
  end
end
