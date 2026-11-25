require "test_helper"

class FaturamentoTest < ActiveSupport::TestCase
  test "resumo separa recebido e a receber e ignora cancelados" do
    r = Pedidos::Faturamento.resumo(Date.current..Date.current)
    assert_equal BigDecimal("59.90"), r.recebido
    assert_equal BigDecimal("199.70"), r.a_receber
    assert_equal 2, r.pedidos
    assert_equal BigDecimal("129.80"), r.ticket_medio
  end

  test "períodos por dia terminam hoje e somam certo" do
    f = Pedidos::Faturamento.new(visao: "dias")
    assert_equal 14, f.periodos.size
    assert_equal Date.current, f.periodos.last.inicio
    assert_equal BigDecimal("259.60"), f.periodos.last.total
    assert_equal BigDecimal("259.60"), f.resumo_do_grafico.total
  end

  test "meses incluem o mês inteiro" do
    Pedido.create!(nome_cliente: "Fim do mês", data: Date.current.end_of_month, pagamento: "pago",
                   itens_attributes: [{ nome: "Torta", quantidade: 1, preco_unitario: 100 }])
    f = Pedidos::Faturamento.new(visao: "meses")
    assert_equal Date.current.beginning_of_month, f.periodos.last.inicio
    assert_equal BigDecimal("159.90"), f.periodos.last.recebido
  end

  test "mais vendidos por quantidade, com valor" do
    top = Pedidos::Faturamento.new.mais_vendidos
    assert_equal ["Brigadeiro gourmet", "Panetone trufado 500g", "Bolo de Natal 1kg"], top.first(3).map(&:nome)
    assert_equal 3, top.second.quantidade
    assert_equal BigDecimal("179.70"), top.second.valor
  end
end
