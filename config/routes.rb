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
  end
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
