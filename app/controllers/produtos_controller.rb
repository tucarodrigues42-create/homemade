class ProdutosController < ApplicationController
  before_action :set_produto, only: %i[show edit update destroy]

  def index
    @produtos = Produto.includes(:ingredientes).em_ordem
  end

  def show
  end

  def new
    @produto = Produto.new(fabricacao: Date.current, vencimento: Date.current + 7, quantidade: 0)
  end

  def edit
  end

  def create
    @produto = Produto.new(produto_params)
    if @produto.save
      redirect_to new_ingrediente_path(produto_id: @produto.id),
                  notice: "Produto cadastrado. Agora adicione os ingredientes dele."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @produto.update(produto_params)
      redirect_to @produto, notice: "Produto atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @produto.destroy
    redirect_to produtos_path, notice: "Produto removido."
  end

  private

  def set_produto
    @produto = Produto.find(params[:id])
  end

  def produto_params
    params.require(:produto).permit(:nome, :descricao, :fabricacao, :vencimento, :quantidade, :preco)
  end
end
