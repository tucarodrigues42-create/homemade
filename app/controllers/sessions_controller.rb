class SessionsController < ApplicationController
  skip_before_action :exigir_login, only: %i[new create]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    usuario = Usuario.find_by(email: params[:email].to_s.strip.downcase)
    if usuario&.authenticate(params[:password])
      reset_session
      session[:usuario_id] = usuario.id
      redirect_to root_path, notice: "Você entrou no sistema da Homemade."
    else
      flash.now[:alert] = "E-mail ou senha incorretos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Você saiu do sistema."
  end
end
