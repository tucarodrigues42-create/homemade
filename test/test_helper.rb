ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module EntrarNoSistema
  def entrar_como(usuario, senha: "senha123")
    post sessions_url, params: { email: usuario.email, password: senha }
  end
end

class ActionDispatch::IntegrationTest
  include EntrarNoSistema
end
