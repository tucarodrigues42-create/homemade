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
    @pedidos_hoje = Pedido.ativos.do_dia(@hoje).includes(:itens).em_ordem.to_a
    @pedidos_semana = Pedido.ativos.where(data: @hoje..(@hoje + DIAS_A_FRENTE - 1)).count
    @a_receber = Pedido.ativos.where(pagamento: "pendente", data: (@hoje - 30)..).sum(:total)
    @producao_hoje = Pedidos::ProducaoDoDia.new(@hoje)
    @alertas = montar_alertas
  end

  # Tela "Mais" do menu do celular: atalhos para o que não cabe na barra de baixo.
  def mais
  end

  private

  def semana_com_contagem
    periodo = @hoje..(@hoje + DIAS_A_FRENTE - 1)
    pedidos = Pedido.ativos.where(data: periodo).group(:data).count
    (0...DIAS_A_FRENTE).map { |i| dia = @hoje + i; [dia, pedidos.fetch(dia, 0)] }
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
