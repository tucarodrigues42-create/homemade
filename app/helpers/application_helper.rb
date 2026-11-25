module ApplicationHelper
  # Botão de excluir que pede confirmação antes (funciona sem JavaScript extra).
  def botao_excluir(registro, texto: "Excluir", pergunta: "Tem certeza que deseja excluir?")
    button_to texto, registro, method: :delete, class: "botao botao-perigo",
              form: { class: "form-inline", onsubmit: "return confirm(#{pergunta.to_json});" }
  end

  def reais(valor)
    number_to_currency(valor || 0, unit: "R$", format: "%u %n", separator: ",", delimiter: ".")
  end

  def data_br(data)
    data.present? ? l(data, format: "%d/%m/%Y") : "—"
  end

  def dia_da_semana(data)
    data.present? ? l(data, format: "%A, %d de %B").capitalize : "Sem data"
  end

  def hora_br(hora)
    hora.present? ? hora.strftime("%H:%M") : nil
  end

  def item_menu(texto, caminho, controlador)
    ativo = controller_name == controlador
    link_to texto, caminho, class: ["menu-item", ("ativo" if ativo)].compact.join(" "),
                            "aria-current": (ativo ? "page" : nil)
  end
end
