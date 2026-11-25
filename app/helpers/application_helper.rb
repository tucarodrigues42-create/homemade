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

  # Ícones simples (traço) desenhados em SVG, sem depender de biblioteca externa.
  ICONES = {
    inicio: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/><path d="M10 21v-6h4v6"/>',
    agenda: '<rect x="3" y="4.5" width="18" height="16.5" rx="2.5"/><path d="M3 9.5h18M8 2.5v4M16 2.5v4"/>',
    clientes: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.8-3.6 3.4-5.5 6.5-5.5s5.7 1.9 6.5 5.5"/><path d="M16 4.8a3.3 3.3 0 0 1 0 6.4M18.5 14.8c1.6.8 2.6 2.5 3 5.2"/>',
    produtos: '<path d="M4 11h16v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1z"/><path d="M4 11c0-3.3 3.6-6 8-6s8 2.7 8 6"/><path d="M12 5V2.5M8 15h.01M12 16h.01M16 15h.01"/>',
    ingredientes: '<path d="M7 3h10M8 3v4.5L4.5 19a1.5 1.5 0 0 0 1.4 2h12.2a1.5 1.5 0 0 0 1.4-2L16 7.5V3"/><path d="M6.5 14h11"/>',
    enderecos: '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
    usuarios: '<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4.2-6 8-6s7 2 8 6"/>',
    mais: '<circle cx="5" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="19" cy="12" r="1.3"/>',
    sair: '<path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3"/><path d="M10 8l-4 4 4 4M6 12h10"/>',
    mais_item: '<path d="M12 5v14M5 12h14"/>',
    alerta: '<path d="M12 3 2.5 20h19z"/><path d="M12 10v4.5M12 17.5h.01"/>',
    seta: '<path d="M9 5l7 7-7 7"/>',
    pedidos: '<path d="M6 3h12l1 4H5z"/><path d="M5 7h14v12.5A1.5 1.5 0 0 1 17.5 21h-11A1.5 1.5 0 0 1 5 19.5z"/><path d="M9 11h6M9 15h4"/>',
    producao: '<path d="M6 13.5a6 6 0 0 1 12 0"/><path d="M3 13.5h18M5 17h14l-1 4H6z"/><path d="M12 4v3.5M8.5 5.5l1 2.5M15.5 5.5l-1 2.5"/>',
    grafico: '<path d="M4 20V4M4 20h16"/><path d="M8 16v-5M12 16V8M16 16v-3M20 16V6"/>',
    whatsapp: '<path d="M4 20l1.3-3.9A8 8 0 1 1 8 18.9z"/><path d="M9 9.5c.3 2 2.5 4.3 4.6 4.8l1.2-1.2 2 .9c-.2 1-1 1.7-2 1.7-3.6 0-6.8-3.2-6.8-6.8 0-1 .7-1.8 1.7-2l.9 2z"/>'
  }.freeze

  def icone(nome, classe: "icone")
    caminho = ICONES.fetch(nome)
    tag.svg(caminho.html_safe, class: classe, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
                               "stroke-width": "1.8", "stroke-linecap": "round", "stroke-linejoin": "round",
                               "aria-hidden": "true", focusable: "false")
  end

  def saudacao
    hora = Time.current.hour
    if hora < 12 then "Bom dia"
    elsif hora < 18 then "Boa tarde"
    else "Boa noite"
    end
  end

  SECOES_MAIS = %w[dashboard agendas produtos enderecos ingredientes usuarios].freeze

  def menu_ativo?(chave)
    case chave
    when "painel" then controller_name == "painel" && action_name == "index"
    when "pedidos" then controller_name == "pedidos" && action_name != "producao"
    when "producao" then controller_name == "pedidos" && action_name == "producao"
    when "mais_topo" then (controller_name == "painel" && action_name == "mais") || %w[enderecos ingredientes usuarios].include?(controller_name)
    when "mais" then (controller_name == "painel" && action_name == "mais") || SECOES_MAIS.include?(controller_name)
    else controller_name == chave
    end
  end

  def item_menu(texto, caminho, chave, icone_nome, classe: "menu-item")
    ativo = menu_ativo?(chave)
    link_to caminho, class: [classe, ("ativo" if ativo)].compact.join(" "), "aria-current": (ativo ? "page" : nil) do
      safe_join([icone(icone_nome), tag.span(texto)])
    end
  end

  def selo_status(pedido)
    tag.span(pedido.status_nome, class: "selo selo-#{pedido.status}")
  end

  def selo_pagamento(pedido)
    tag.span(pedido.pago? ? "Pago" : "A receber", class: "selo #{pedido.pago? ? 'selo-pago' : 'selo-pendente'}")
  end

  def selo_entrega(pedido)
    tag.span(pedido.entrega? ? "Entrega" : "Retirada", class: "selo selo-#{pedido.tipo_entrega}")
  end

  # Texto curto dos itens: "2× Panetone, 1× Bolo de Natal"
  def resumo_itens(pedido, limite: 4)
    itens = pedido.itens.to_a
    texto = itens.first(limite).map { |i| "#{i.quantidade}× #{i.nome}" }.join(", ")
    texto += " e mais #{itens.size - limite}" if itens.size > limite
    texto
  end

  # Mensagem pronta para mandar ao cliente pelo WhatsApp.
  def mensagem_whatsapp(pedido)
    linhas = ["Olá, #{pedido.nome_cliente.split.first}! Aqui é da Homemade Confeitaria.",
              "Seu pedido #{pedido.numero} para #{l(pedido.data, format: '%d/%m')}#{" às #{hora_br(pedido.horario)}" if pedido.horario}:"]
    pedido.itens.each { |i| linhas << "• #{i.quantidade}× #{i.nome}" }
    linhas << "Total: #{reais(pedido.total)}#{' (pago)' if pedido.pago?}"
    linhas << (pedido.entrega? ? "Entrega em: #{pedido.endereco_entrega}" : "Retirada na loja.")
    linhas.join("\n")
  end

  def whatsapp_pedido_url(pedido)
    return unless pedido.whatsapp_url
    "#{pedido.whatsapp_url}?text=#{ERB::Util.url_encode(mensagem_whatsapp(pedido))}"
  end

  # Valor curto para eixos: R$ 1,2 mil
  def reais_curto(valor)
    valor = valor.to_d
    return "R$ 0" if valor.zero?
    return "R$ #{number_with_precision(valor / 1000, precision: (valor >= 10_000 ? 0 : 1), separator: ',', strip_insignificant_zeros: true)} mil" if valor >= 1000
    "R$ #{number_with_precision(valor, precision: 0, delimiter: '.')}"
  end

  # Marca "bonita" para o topo do eixo (1, 2, 2,5 ou 5 × 10^n).
  def topo_do_eixo(maximo)
    maximo = maximo.to_f
    return 100 if maximo <= 0
    base = 10**Math.log10(maximo).floor
    [1, 2, 2.5, 5, 10].map { |m| m * base }.find { |v| v >= maximo }
  end

  def variacao_percentual(atual, anterior)
    return nil if anterior.to_d.zero?
    ((atual.to_d - anterior.to_d) / anterior.to_d * 100).round
  end
end
