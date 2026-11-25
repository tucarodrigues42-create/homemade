# Cria o primeiro acesso da Homemade Confeitaria.
# Defina ADMIN_EMAIL e ADMIN_SENHA no servidor; se não definir, usa os valores abaixo.
# Troque a senha no primeiro acesso, em Usuários > Editar.
email = ENV.fetch("ADMIN_EMAIL", "admin@homemade.com")
senha = ENV.fetch("ADMIN_SENHA", "homemade123")

Usuario.find_or_create_by!(email: email) do |usuario|
  usuario.password = senha
  usuario.password_confirmation = senha
  usuario.adm = true
end

puts "Administrador pronto: #{email}"
