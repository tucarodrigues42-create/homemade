class PedidosController < ApplicationController
  before_action :set_pedido, only: %i[show edit update destroy status pagamento]
  before_action :carregar_opcoes, only: %i[new edit create update]

  ITENS_EM_BRANCO = 1
  POR_PAGINA = 40

  def index
    @dia = ler_data(params[:dia])
    @filtros = params.permit(:q, :dia, :tipo, :pagamento, :status, :periodo).to_h.symbolize_keys
    @periodo = params[:periodo].presence || (@dia ? "dia" : "proximos")

    @pedidos = Pedido.em_ordem
    @pedidos = case @periodo
               when "dia" then @pedidos.do_dia(@dia || Date.current)
               when "proximos" then @pedidos.where(data: Date.current..)
               when "anteriores" then @pedidos.where(data: ...Date.current).reorder(data: :desc, horario: :desc)
               else @pedidos
               end
    @pedidos = @pedidos.buscar(params[:q])
    @pedidos = @pedidos.where(tipo_entrega: params[:tipo]) if Pedido::TIPOS_ENTREGA.key?(params[:tipo])
    @pedidos = @pedidos.where(pagamento: params[:pagamento]) if Pedido::PAGAMENTOS.key?(params[:pagamento])
    if params[:status] == "abertos"
      @pedidos = @pedidos.em_aberto
    elsif Pedido::STATUS.key?(params[:status])
      @pedidos = @pedidos.where(status: params[:status])
    end

    @dia_exibido = @dia || Date.current if @periodo == "dia"

    # Totais calculados no banco, sobre todos os pedidos filtrados.
    quantidade, total, a_receber = @pedidos.unscope(:order).pick(
      Arel.sql("COUNT(*)"),
      Arel.sql("COALESCE(SUM(CASE WHEN status <> 'cancelado' THEN total END), 0)"),
      Arel.sql("COALESCE(SUM(CASE WHEN status <> 'cancelado' AND pagamento <> 'pago' THEN total END), 0)")
    )
    @quantidade = quantidade.to_i
    @total_valor = total.to_d
    @a_receber = a_receber.to_d

    # Mostra aos poucos: listas longas (ex.: "Todos") abrem rápido e carregam mais ao tocar.
    @limite = params[:limite].to_i.clamp(POR_PAGINA, 2000)
    @pedidos = @pedidos.includes(:itens).limit(@limite).to_a
    @tem_mais = @quantidade > @pedidos.size
  end

  def producao
    @dia = ler_data(params[:dia]) || Date.current
    @incluir_entregues = params[:entregues] != "0"
    @producao = Pedidos::ProducaoDoDia.new(@dia, incluir_entregues: @incluir_entregues)
    @pedidos = @producao.pedidos.includes(:itens).em_ordem
  end

  def show
  end

  def new
    @pedido = Pedido.new(data: ler_data(params[:dia]) || Date.current, cliente_id: params[:cliente_id])
    if @pedido.cliente
      @pedido.nome_cliente = @pedido.cliente.nome
      @pedido.whatsapp = @pedido.cliente.celular
    end
    completar_itens
  end

  def edit
    completar_itens
  end

  def create
    @pedido = Pedido.new(pedido_params)
    if @pedido.save
      redirect_to @pedido, notice: "Pedido #{@pedido.numero} salvo."
    else
      completar_itens
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @pedido.update(pedido_params)
      redirect_to @pedido, notice: "Pedido #{@pedido.numero} atualizado."
    else
      completar_itens
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pedido.destroy
    redirect_to pedidos_path, notice: "Pedido #{@pedido.numero} excluído."
  end

  # Avança (ou volta) a etapa do pedido com um toque.
  def status
    if @pedido.mudar_status!(params[:status])
      redirect_back fallback_location: @pedido, notice: "Pedido #{@pedido.numero}: #{@pedido.status_nome}."
    else
      redirect_back fallback_location: @pedido, alert: @pedido.errors.full_messages.to_sentence
    end
  end

  def pagamento
    novo = @pedido.pago? ? "pendente" : "pago"
    @pedido.update_columns(pagamento: novo, updated_at: Time.current)
    redirect_back fallback_location: @pedido,
                  notice: "Pedido #{@pedido.numero} marcado como #{Pedido::PAGAMENTOS[novo].downcase}."
  end

  private

  def set_pedido
    @pedido = Pedido.includes(itens: :produto).find(params[:id])
  end

  def carregar_opcoes
    @produtos = Produto.em_ordem
    @clientes = Cliente.includes(:endereco).em_ordem
  end

  def completar_itens
    faltam = ITENS_EM_BRANCO - @pedido.itens.reject(&:marked_for_destruction?).count { |i| i.new_record? }
    faltam = 1 if faltam < 1 && @pedido.itens.any?
    faltam.times { @pedido.itens.build }
  end

  def ler_data(valor)
    Date.parse(valor) if valor.present?
  rescue Date::Error
    nil
  end

  def pedido_params
    params.require(:pedido).permit(
      :cliente_id, :nome_cliente, :whatsapp, :tipo_entrega, :endereco_entrega, :data, :horario,
      :status, :pagamento, :forma_pagamento, :taxa_entrega, :desconto, :descricao,
      itens_attributes: %i[id produto_id nome quantidade preco_unitario observacao _destroy]
    )
  end
end
