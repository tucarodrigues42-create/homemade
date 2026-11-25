require "test_helper"

class ClienteTest < ActiveSupport::TestCase
  test "limpa e formata o WhatsApp" do
    cliente = Cliente.new(nome: "Teste Silva", celular: "+55 (82) 99999-1234")
    assert cliente.valid?, cliente.errors.full_messages.to_sentence
    assert_equal "82999991234", cliente.celular
    assert_equal "(82) 99999-1234", cliente.celular_formatado
    assert_equal "https://wa.me/5582999991234", cliente.whatsapp_url
  end

  test "WhatsApp é obrigatório e precisa de DDD" do
    assert_not Cliente.new(nome: "Teste", celular: "").valid?
    assert_not Cliente.new(nome: "Teste", celular: "99999123").valid?
  end

  test "mensagens de erro em português" do
    cliente = Cliente.new
    cliente.valid?
    assert_includes cliente.errors.full_messages, "Nome não pode ficar em branco"
  end
end
