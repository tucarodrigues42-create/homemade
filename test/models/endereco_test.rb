require "test_helper"

class EnderecoTest < ActiveSupport::TestCase
  test "aceita CEP com traço" do
    endereco = Endereco.new(rua: "Rua A", numero: "1", bairro: "Centro", cidade: "Arapiraca", estado: "AL", cep: "57300-000")
    assert endereco.valid?
    assert_equal "57300000", endereco.cep
    assert_equal "57300-000", endereco.cep_formatado
  end

  test "rejeita CEP incompleto" do
    assert_not Endereco.new(rua: "Rua A", numero: "1", bairro: "Centro", cidade: "Arapiraca", estado: "AL", cep: "5730").valid?
  end
end
