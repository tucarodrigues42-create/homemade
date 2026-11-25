require "test_helper"

class AgendaTest < ActiveSupport::TestCase
  test "ordena pela data mais próxima" do
    assert_equal agendas(:entrega), Agenda.em_ordem.first
  end
end
