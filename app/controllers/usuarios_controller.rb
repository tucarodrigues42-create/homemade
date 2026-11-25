class UsuariosController < ApplicationController
  before_action :set_usuario, only: %i[show edit update destroy]
  before_action :exigir_admin, only: %i[new create destroy]
  before_action :exigir_dono_ou_admin, only: %i[edit update]

  def index
    @usuarios = Usuario.em_ordem
  end

  def show
  end

  def new
    @usuario = Usuario.new
  end

  def edit
  end

  def create
    @usuario = Usuario.new(usuario_params)
    if @usuario.save
      redirect_to usuarios_path, notice: "Usuário cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    atributos = usuario_params
    atributos = atributos.except(:password, :password_confirmation) if atributos[:password].blank?
    if @usuario.update(atributos)
      redirect_to @usuario, notice: "Usuário atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @usuario == current_user
      redirect_to usuarios_path, alert: "Você não pode remover a própria conta."
    else
      @usuario.destroy
      redirect_to usuarios_path, notice: "Usuário removido."
    end
  end

  private

  def set_usuario
    @usuario = Usuario.find(params[:id])
  end

  def exigir_dono_ou_admin
    return if current_user.adm? || current_user == @usuario
    redirect_to usuarios_path, alert: "Somente o dono da conta pode alterá-la."
  end

  def usuario_params
    permitidos = %i[email password password_confirmation]
    permitidos << :adm if current_user.adm? && current_user != @usuario
    params.require(:usuario).permit(permitidos)
  end
end
