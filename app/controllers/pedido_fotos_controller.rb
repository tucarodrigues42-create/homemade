# Fotos de referência do pedido: enviar, ver e apagar.
class PedidoFotosController < ApplicationController
  before_action :set_pedido

  def create
    arquivos = Array(params[:fotos]).select { |a| a.respond_to?(:read) }
    return redirect_to(@pedido, alert: "Escolha pelo menos uma foto.") if arquivos.empty?

    fotos = arquivos.map { |a| PedidoFoto.do_arquivo(a).tap { |f| f.pedido = @pedido } }
    invalidas = fotos.reject(&:valid?)
    if invalidas.any?
      redirect_to @pedido, alert: invalidas.map { |f| "Foto \"#{f.nome}\": #{f.errors.full_messages.to_sentence}" }.join(" ")
    else
      PedidoFoto.transaction { fotos.each(&:save!) }
      redirect_to @pedido, notice: fotos.size == 1 ? "Foto anexada." : "#{fotos.size} fotos anexadas."
    end
  end

  def show
    foto = @pedido.fotos.find(params[:id])
    # A foto nunca muda depois de enviada: o celular pode guardar em cache.
    response.headers["Cache-Control"] = "private, max-age=31536000, immutable"
    send_data foto.dados, type: foto.content_type, disposition: "inline", filename: foto.nome.presence || "foto-#{foto.id}"
  end

  def destroy
    @pedido.fotos.sem_dados.find(params[:id]).destroy
    redirect_to @pedido, notice: "Foto apagada."
  end

  private

  def set_pedido
    @pedido = Pedido.find(params[:pedido_id])
  end
end
