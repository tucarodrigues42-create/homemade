# Tela de backup: baixar planilhas (CSV), baixar a cópia completa e restaurar.
class BackupsController < ApplicationController
  before_action :exigir_admin_backup, only: :restaurar

  TAMANHO_MAXIMO = 4.megabytes

  def index
    @totais = { clientes: Cliente.count, pedidos: Pedido.count, itens: PedidoItem.count }
  end

  def clientes
    baixar_csv Backup::Planilhas.new.clientes, "clientes"
  end

  def pedidos
    baixar_csv planilhas.pedidos, "pedidos"
  end

  def itens
    baixar_csv planilhas.itens, "itens-dos-pedidos"
  end

  def completo
    send_data JSON.pretty_generate(Backup::Completo.gerar),
              filename: "homemade-backup-#{Time.current.strftime('%Y-%m-%d-%Hh%M')}.json",
              type: "application/json", disposition: "attachment"
  end

  def restaurar
    arquivo = params[:arquivo]
    return redirect_to(backup_path, alert: "Escolha o arquivo de backup (.json).") unless arquivo.respond_to?(:read)
    return redirect_to(backup_path, alert: "Arquivo grande demais para um backup.") if arquivo.size > TAMANHO_MAXIMO

    resultado = Backup::Completo.restaurar(arquivo.read.force_encoding("UTF-8"))
    redirect_to backup_path, notice: "Backup restaurado: #{Backup::Completo.resumo(resultado)}."
  rescue Backup::Completo::ArquivoInvalido => e
    redirect_to backup_path, alert: e.message
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("Falha ao restaurar backup: #{e.class}: #{e.message}")
    redirect_to backup_path, alert: "Não foi possível restaurar: o arquivo tem dados que não combinam com o sistema. Nada foi alterado."
  end

  private

  def planilhas
    Backup::Planilhas.new(de: ler_data(params[:de]), ate: ler_data(params[:ate]))
  end

  def baixar_csv(conteudo, nome)
    send_data conteudo, filename: "homemade-#{nome}-#{Date.current.strftime('%Y-%m-%d')}.csv",
                        type: "text/csv; charset=utf-8", disposition: "attachment"
  end

  def ler_data(valor)
    Date.parse(valor) if valor.present?
  rescue Date::Error
    nil
  end

  def exigir_admin_backup
    return if current_user&.adm?
    redirect_to backup_path, alert: "Somente o administrador pode restaurar um backup."
  end
end
