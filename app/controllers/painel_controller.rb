class PainelController < ApplicationController
  DIAS_A_FRENTE = 7

  def index
    @hoje = Date.current
    agenda = Agenda.where(data: @hoje..(@hoje + DIAS_A_FRENTE)).em_ordem.to_a
    @agenda_hoje, @proximos = agenda.partition { |a| a.data == @hoje }
    @semana = semana_com_contagem

    inicio_mes = @hoje.beginning_of_month.beginning_of_day
    @total_clientes, @clientes_novos_mes = Cliente.pick(
      Arel.sql("COUNT(*)"), Arel.sql(Cliente.sanitize_sql_array(["COUNT(CASE WHEN created_at >= ? THEN 1 END)", inicio_mes]))
    ).map(&:to_i)
    @produtos, @unidades_em_estoque = Produto.pick(Arel.sql("COUNT(*)"), Arel.sql("COALESCE(SUM(quantidade), 0)")).map(&:to_i)
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
    # Uma consulta para produtos e uma para ingredientes, em vez de uma por tipo de alerta.
    produtos = Produto.where(vencimento: ..limite).or(Produto.where(quantidade: 0)).em_ordem.to_a
    produtos.select { |p| p.vencimento && p.vencimento < @hoje }.each do |p|
      alertas << { tipo: :erro, texto: "#{p.nome} está vencido desde #{p.vencimento.strftime('%d/%m')}", link: p }
    end
    produtos.select { |p| p.vencimento && p.vencimento >= @hoje && p.vencimento <= limite }.each do |p|
      alertas << { tipo: :aviso, texto: "#{p.nome} vence em #{p.vencimento.strftime('%d/%m')}", link: p }
    end
    produtos.select { |p| p.quantidade.to_i.zero? }.each do |p|
      alertas << { tipo: :aviso, texto: "#{p.nome} está sem estoque", link: p }
    end
    ingredientes = Ingrediente.where(vencimento: ..limite).or(Ingrediente.where(quantidade: 0)).em_ordem.to_a
    ingredientes.select { |i| i.vencimento && i.vencimento <= limite }.each do |i|
      verbo = i.vencido? ? "venceu em" : "vence em"
      alertas << { tipo: (i.vencido? ? :erro : :aviso), texto: "Ingrediente #{i.nome} #{verbo} #{i.vencimento.strftime('%d/%m')}", link: i }
    end
    ingredientes.select { |i| i.quantidade.to_i.zero? }.each do |i|
      alertas << { tipo: :aviso, texto: "Ingrediente #{i.nome} acabou", link: i }
    end
    alertas
  end
end
