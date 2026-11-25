class ApplicationController < ActionController::Base
  before_action :exigir_login
  helper_method :logged_in?, :current_user

  private

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = session[:usuario_id] && Usuario.find_by(id: session[:usuario_id])
  end

  def logged_in?
    current_user.present?
  end

  def exigir_login
    return if logged_in?
    redirect_to login_path, alert: "Entre com seu e-mail e senha para continuar."
  end

  def exigir_admin
    return if current_user&.adm?
    redirect_to usuarios_path, alert: "Somente o administrador pode fazer isso."
  end
end
