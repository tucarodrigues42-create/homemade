Rails.application.routes.draw do
  root "painel#index"
  get "/mais", to: "painel#mais", as: :mais

  get "/dashboard", to: "dashboard#index", as: :dashboard
  get "/producao", to: "pedidos#producao", as: :producao
  resources :pedidos do
    member do
      patch :status
      patch :pagamento
    end
    resources :fotos, only: %i[create show destroy], controller: "pedido_fotos"
  end

  # Backup: planilhas (CSV) e cópia completa para guardar ou restaurar
  get  "/backup", to: "backups#index", as: :backup
  get  "/backup/clientes", to: "backups#clientes", as: :backup_clientes
  get  "/backup/pedidos", to: "backups#pedidos", as: :backup_pedidos
  get  "/backup/itens", to: "backups#itens", as: :backup_itens
  get  "/backup/completo", to: "backups#completo", as: :backup_completo
  post "/backup/restaurar", to: "backups#restaurar", as: :backup_restaurar
  resources :agendas
  resources :clientes
  resources :enderecos
  resources :produtos
  resources :ingredientes
  resources :usuarios

  get    "/login",    to: "sessions#new",     as: :login
  post   "/sessions", to: "sessions#create",  as: :sessions
  delete "/sessions", to: "sessions#destroy"

  # Verificação de saúde usada pelo servidor de hospedagem
  get "up" => "rails/health#show", as: :rails_health_check
end
