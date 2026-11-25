class IngredientesController < ApplicationController
  before_action :set_ingrediente, only: %i[show edit update destroy]
  before_action :set_produtos, only: %i[new create edit update]

  def index
    @ingredientes = Ingrediente.includes(:produto).em_ordem
  end

  def show
  end

  def new
    @ingrediente = Ingrediente.new(produto_id: params[:produto_id], vencimento: Date.current + 30, quantidade: 0)
  end

  def edit
  end

  def create
    @ingrediente = Ingrediente.new(ingrediente_params)
    if @ingrediente.save
      redirect_to @ingrediente.produto, notice: "Ingrediente adicionado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @ingrediente.update(ingrediente_params)
      redirect_to @ingrediente, notice: "Ingrediente atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ingrediente.destroy
    redirect_to ingredientes_path, notice: "Ingrediente removido."
  end

  private

  def set_ingrediente
    @ingrediente = Ingrediente.find(params[:id])
  end

  def set_produtos
    @produtos = Produto.em_ordem.pluck(:nome, :id)
  end

  def ingrediente_params
    params.require(:ingrediente).permit(:nome, :descricao, :preco, :quantidade, :vencimento, :produto_id)
  end
end
