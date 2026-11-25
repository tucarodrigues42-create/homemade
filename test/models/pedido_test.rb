require "test_helper"

class PedidoTest < ActiveSupport::TestCase
  test "calcula o total com itens, taxa e desconto, congelando o preço do produto" do
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current, taxa_entrega: 10, desconto: 5,
                        tipo_entrega: "entrega", endereco_entrega: "Rua A, 1",
                        itens_attributes: [{ produto_id: produtos(:panetone).id, quantidade: 3 },
                                           { nome: "Brigadeiro", quantidade: 10, preco_unitario: "2.50" }])
    assert pedido.save, pedido.errors.full_messages.to_sentence
    item = pedido.itens.first
    assert_equal "Panetone trufado 500g", item.nome
    assert_equal BigDecimal("59.90"), item.preco_unitario
    assert_equal BigDecimal("209.70"), pedido.total  # 179,70 + 25,00 + 10 - 5

    produtos(:panetone).update!(preco: 70)
    assert_equal BigDecimal("59.90"), item.reload.preco_unitario
  end

  test "linhas em branco do formulário são ignoradas" do
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current, descricao: "Bolo",
                        itens_attributes: [{ produto_id: "", nome: "", quantidade: "1" }])
    assert pedido.save
    assert_empty pedido.itens
  end

  test "exige item ou descrição" do
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current)
    assert_not pedido.valid?
    assert_includes pedido.errors[:base].join, "pelo menos um item"
  end

  test "entrega exige endereço" do
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current, descricao: "x", tipo_entrega: "entrega")
    assert_not pedido.valid?
    assert pedido.errors[:endereco_entrega].any?
  end

  test "usa o endereço e o WhatsApp do cliente cadastrado" do
    pedido = Pedido.create!(cliente: clientes(:maria), nome_cliente: "", data: Date.current, descricao: "x", tipo_entrega: "entrega")
    assert_equal "Maria das Graças", pedido.nome_cliente
    assert_equal "82999990000", pedido.whatsapp
    assert pedido.endereco_entrega.present?
  end

  test "limpa o WhatsApp" do
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current, descricao: "x", whatsapp: "+55 (82) 99123-4567")
    assert pedido.valid?
    assert_equal "82991234567", pedido.whatsapp
  end

  test "muda de etapa, inclusive pulando ou voltando" do
    pedido = pedidos(:maria_hoje)
    assert_not pedido.mudar_status!("inventada")
    assert_equal "novo", pedido.reload.status
    assert pedido.mudar_status!("em_producao")
    assert pedido.mudar_status!("confirmado")
    assert pedido.mudar_status!("entregue")
    assert_equal "entregue", pedido.reload.status
  end

  test "próxima etapa e texto do botão" do
    pedido = pedidos(:maria_hoje) # entrega, etapa "novo"
    assert_equal "confirmado", pedido.proximo_status
    assert_equal "Confirmar pedido", pedido.acao_proximo
    assert_equal 1, pedido.passo
    pedido.status = "pronto"
    assert_equal "Marcar como entregue", pedido.acao_proximo
    pedido.tipo_entrega = "retirada"
    assert_equal "Cliente retirou", pedido.acao_proximo
    pedido.status = "entregue"
    assert_nil pedido.proximo_status
    pedido.status = "cancelado"
    assert_nil pedido.acao_proximo
  end

  test "anexa fotos ao salvar o pedido" do
    foto = Rack::Test::UploadedFile.new(file_fixture("bolo.png"), "image/png")
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current, descricao: "Bolo igual à foto", novas_fotos: [foto])
    assert pedido.save
    assert_equal 1, pedido.fotos.count
    assert_equal 1, pedido.reload.fotos_count
    assert_equal File.binread(file_fixture("bolo.png")), pedido.fotos.first.dados
  end

  test "recusa arquivo que não é foto" do
    texto = Rack::Test::UploadedFile.new(StringIO.new("oi"), "text/plain", original_filename: "nota.txt")
    pedido = Pedido.new(nome_cliente: "Carla", data: Date.current, descricao: "x", novas_fotos: [texto])
    assert_not pedido.save
    assert_match "nota.txt", pedido.errors.full_messages.to_sentence
  end

  test "busca por nome, telefone, item e número" do
    assert_includes Pedido.buscar("maria"), pedidos(:maria_hoje)
    assert_includes Pedido.buscar("8877"), pedidos(:joao_hoje)
    assert_includes Pedido.buscar("ninho"), pedidos(:ana_amanha)
    assert_equal [pedidos(:joao_hoje)], Pedido.buscar("BRIGADEIRO").to_a
    assert_equal [pedidos(:joao_hoje)], Pedido.buscar("##{pedidos(:joao_hoje).id}").to_a
  end
end
