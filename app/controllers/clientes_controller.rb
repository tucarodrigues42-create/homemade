class ClientesController < ApplicationController
  before_action :set_cliente, only: %i[show edit update destroy]

  def index
    @busca = params[:busca].to_s.strip
    @clientes = Cliente.includes(:endereco).em_ordem
    if @busca.present?
      termo = "%#{Cliente.sanitize_sql_like(@busca)}%"
      digitos = @busca.gsub(/\D/, "")
      @clientes = if digitos.length >= 4
        @clientes.where("nome LIKE :t OR celular LIKE :d OR telefone LIKE :d", t: termo, d: "%#{digitos}%")
      else
        @clientes.where("nome LIKE :t", t: termo)
      end
    end
  end

  def show
  end

  def new
    @cliente = Cliente.new
    @cliente.build_endereco(cidade: "Arapiraca", estado: "AL")
  end

  def edit
    @cliente.build_endereco(cidade: "Arapiraca", estado: "AL") if @cliente.endereco.nil?
  end

  def create
    @cliente = Cliente.new(cliente_params)
    if @cliente.save
      redirect_to @cliente, notice: "Cliente cadastrado."
    else
      @cliente.build_endereco(cidade: "Arapiraca", estado: "AL") if @cliente.endereco.nil?
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @cliente.update(cliente_params)
      redirect_to @cliente, notice: "Cliente atualizado."
    else
      @cliente.build_endereco(cidade: "Arapiraca", estado: "AL") if @cliente.endereco.nil?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cliente.destroy
    redirect_to clientes_path, notice: "Cliente removido."
  end

  private

  def set_cliente
    @cliente = Cliente.find(params[:id])
  end

  def cliente_params
    params.require(:cliente).permit(
      :nome, :telefone, :celular, :email,
      endereco_attributes: %i[id rua numero bairro cidade cep estado complemento]
    )
  end
end
