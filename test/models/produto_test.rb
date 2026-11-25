require "test_helper"

class ProdutoTest < ActiveSupport::TestCase
  test "produto vencido" do
    produto = produtos(:bolo)
    assert_not produto.vencido?
    produto.vencimento = Date.current - 1
    assert produto.vencido?
  end

  test "nome único" do
    assert_not Produto.new(produtos(:bolo).attributes.except("id")).valid?
  end
end
