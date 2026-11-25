require "test_helper"

class AgendasControllerTest < ActionDispatch::IntegrationTest
  setup { entrar_como usuarios(:equipe) }

  test "lista a agenda" do
    get agendas_url
    assert_response :success
    assert_select ".item", 2
  end

  test "filtra a agenda por dia" do
    get agendas_url(dia: Date.current)
    assert_response :success
    assert_select ".item", 1
    assert_match "panetones", response.body
  end

  test "cria compromisso" do
    assert_difference("Agenda.count") do
      post agendas_url, params: { agenda: { mensagem: "Retirada: 3 caixas de brigadeiro", data: Date.current, horario: "10:30" } }
    end
    assert_redirected_to agendas_url
  end

  test "não cria compromisso sem descrição" do
    assert_no_difference("Agenda.count") do
      post agendas_url, params: { agenda: { mensagem: "", data: Date.current } }
    end
    assert_response :unprocessable_entity
  end

  test "mostra, edita e atualiza" do
    get agenda_url(agendas(:entrega))
    assert_response :success
    get edit_agenda_url(agendas(:entrega))
    assert_response :success
    patch agenda_url(agendas(:entrega)), params: { agenda: { mensagem: "Entregar 3 panetones" } }
    assert_redirected_to agendas_url
    assert_equal "Entregar 3 panetones", agendas(:entrega).reload.mensagem
  end

  test "exclui compromisso" do
    assert_difference("Agenda.count", -1) { delete agenda_url(agendas(:entrega)) }
    assert_redirected_to agendas_url
  end
end
