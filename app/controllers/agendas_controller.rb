class AgendasController < ApplicationController
  before_action :set_agenda, only: %i[show edit update destroy]

  def index
    @dia = params[:dia].present? ? (Date.parse(params[:dia]) rescue nil) : nil
    @agendas = Agenda.em_ordem
    @agendas = @agendas.do_dia(@dia) if @dia
  end

  def show
  end

  def new
    @agenda = Agenda.new(data: params[:dia].presence || Date.current)
  end

  def edit
  end

  def create
    @agenda = Agenda.new(agenda_params)
    if @agenda.save
      redirect_to agendas_path, notice: "Compromisso salvo na agenda."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @agenda.update(agenda_params)
      redirect_to agendas_path, notice: "Compromisso atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @agenda.destroy
    redirect_to agendas_path, notice: "Compromisso removido da agenda."
  end

  private

  def set_agenda
    @agenda = Agenda.find(params[:id])
  end

  def agenda_params
    params.require(:agenda).permit(:mensagem, :data, :horario)
  end
end
