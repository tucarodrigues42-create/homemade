class DashboardController < ApplicationController
  def index
    @hoje = Date.current
    @faturamento = Pedidos::Faturamento.new(visao: params[:ver], hoje: @hoje)
    @dia = Pedidos::Faturamento.resumo(@hoje..@hoje)
    @semana = Pedidos::Faturamento.resumo(@hoje.beginning_of_week..@hoje.end_of_week)
    @mes = Pedidos::Faturamento.resumo(@hoje.beginning_of_month..@hoje.end_of_month)
    @mes_passado = Pedidos::Faturamento.resumo((@hoje.beginning_of_month << 1)..(@hoje.beginning_of_month - 1))
    @mais_vendidos = @faturamento.mais_vendidos
  end
end
