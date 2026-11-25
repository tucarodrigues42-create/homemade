class PainelController < ApplicationController
  DIAS_A_FRENTE = 7

  def index
    @hoje = Date.current
    @agenda_hoje = Agenda.do_dia(@hoje).em_ordem
    @proximos = Agenda.where(data: (@hoje + 1)..(@hoje + DIAS_A_FRENTE)).em_ordem
    @semana = semana_com_contagem
    @sem_data = Agenda.where(data: nil).count

    @total_clientes = Cliente.count
    @clientes_novos_mes = Cliente.where(created_at: @hoje.beginning_of_month.beginning_of_day..).count
    @clientes_retirada = Cliente.where(endereco_id: nil).count

    @produtos = Produto.count
    @unidades_em_estoque = Produto.sum(:quantidade)
    @alertas = montar_alertas
  end

  # Tela "Mais" do menu do celular: atalhos para o que não cabe na barra de baixo.
  def mais
  end

  private

  def semana_com_contagem
    contagem = Agenda.where(data: @hoje..(@hoje + DIAS_A_FRENTE - 1)).group(:data).count
    (0...DIAS_A_FRENTE).map { |i| dia = @hoje + i; [dia, contagem.fetch(dia, 0)] }
  end

  def montar_alertas
    limite = @hoje + 3
    alertas = []
    Produto.where(vencimento: ...@hoje).em_ordem.each do |p|
      alertas << { tipo: :erro, texto: "#{p.nome} está vencido desde #{p.vencimento.strftime('%d/%m')}", link: p }
    end
    Produto.where(vencimento: @hoje..limite).em_ordem.each do |p|
      alertas << { tipo: :aviso, texto: "#{p.nome} vence em #{p.vencimento.strftime('%d/%m')}", link: p }
    end
    Produto.where(quantidade: 0).em_ordem.each do |p|
      alertas << { tipo: :aviso, texto: "#{p.nome} está sem estoque", link: p }
    end
    Ingrediente.includes(:produto).where(vencimento: ..limite).em_ordem.each do |i|
      verbo = i.vencido? ? "venceu em" : "vence em"
      alertas << { tipo: (i.vencido? ? :erro : :aviso), texto: "Ingrediente #{i.nome} #{verbo} #{i.vencimento.strftime('%d/%m')}", link: i }
    end
    Ingrediente.where(quantidade: 0).em_ordem.each do |i|
      alertas << { tipo: :aviso, texto: "Ingrediente #{i.nome} acabou", link: i }
    end
    alertas
  end
end
