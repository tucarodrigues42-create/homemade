require "test_helper"

class ProducaoDoDiaTest < ActiveSupport::TestCase
  test "soma cada produto do dia e ignora cancelados" do
    producao = Pedidos::ProducaoDoDia.new(Date.current)
    linhas = producao.linhas.to_h { |l| [l.nome, l.quantidade] }
    assert_equal({ "Brigadeiro gourmet" => 25, "Panetone trufado 500g" => 3, "Bolo de Natal 1kg" => 1 }, linhas)
    assert_equal 29, producao.total_unidades
    assert_equal 2, producao.linhas.find { |l| l.nome.start_with?("Panetone") }.pedidos
  end

  test "pode contar só o que falta entregar" do
    pedidos(:joao_hoje).update!(status: "entregue")
    producao = Pedidos::ProducaoDoDia.new(Date.current, incluir_entregues: false)
    assert_equal({ "Panetone trufado 500g" => 2, "Bolo de Natal 1kg" => 1 }, producao.linhas.to_h { |l| [l.nome, l.quantidade] })
  end

  test "itens escritos à mão com maiúsculas diferentes viram uma linha só" do
    Pedido.create!(nome_cliente: "Rita", data: Date.current, itens_attributes: [{ nome: "brigadeiro gourmet ", quantidade: 5 }])
    linha = Pedidos::ProducaoDoDia.new(Date.current).linhas.find { |l| l.nome.downcase.start_with?("brigadeiro") }
    assert_equal 30, linha.quantidade
    assert_equal 2, linha.pedidos
  end

  test "usa o nome atual do produto" do
    produtos(:bolo).update!(nome: "Bolo natalino 1kg")
    assert_includes Pedidos::ProducaoDoDia.new(Date.current).linhas.map(&:nome), "Bolo natalino 1kg"
  end

  test "dia sem pedidos" do
    producao = Pedidos::ProducaoDoDia.new(Date.current + 30)
    assert_empty producao.linhas
    assert_equal 0, producao.total_unidades
  end
end
