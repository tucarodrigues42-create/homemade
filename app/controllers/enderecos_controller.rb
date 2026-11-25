class EnderecosController < ApplicationController
  before_action :set_endereco, only: %i[show edit update destroy]

  def index
    @enderecos = Endereco.includes(:clientes).em_ordem
  end

  def show
  end

  def new
    @endereco = Endereco.new(cidade: "Arapiraca", estado: "AL")
  end

  def edit
  end

  def create
    @endereco = Endereco.new(endereco_params)
    if @endereco.save
      redirect_to @endereco, notice: "Endereço cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @endereco.update(endereco_params)
      redirect_to @endereco, notice: "Endereço atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @endereco.destroy
    redirect_to enderecos_path, notice: "Endereço removido."
  end

  private

  def set_endereco
    @endereco = Endereco.find(params[:id])
  end

  def endereco_params
    params.require(:endereco).permit(:rua, :numero, :bairro, :cidade, :cep, :estado, :complemento)
  end
end
