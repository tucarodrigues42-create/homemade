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

  test "respeita as etapas permitidas" do
    pedido = pedidos(:maria_hoje)
    assert_not pedido.mudar_status!("entregue")
    assert_equal "novo", pedido.reload.status
    assert pedido.mudar_status!("em_producao")
    assert pedido.mudar_status!("pronto")
    assert pedido.mudar_status!("entregue")
    assert_equal "entregue", pedido.reload.status
  end

  test "busca por nome, telefone, item e número" do
    assert_includes Pedido.buscar("maria"), pedidos(:maria_hoje)
    assert_includes Pedido.buscar("8877"), pedidos(:joao_hoje)
    assert_includes Pedido.buscar("ninho"), pedidos(:ana_amanha)
    assert_equal [pedidos(:joao_hoje)], Pedido.buscar("BRIGADEIRO").to_a
    assert_equal [pedidos(:joao_hoje)], Pedido.buscar("##{pedidos(:joao_hoje).id}").to_a
  end
end
