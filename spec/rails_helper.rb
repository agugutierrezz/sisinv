ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
abort("Running in production!") if Rails.env.production?
require "rspec/rails"

# FactoryBot
RSpec.configure { |c| c.include FactoryBot::Syntax::Methods }

# DatabaseCleaner
RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) { |ex| DatabaseCleaner.cleaning { ex.run } }
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Cargar helpers/contexts de support/
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Ya que todos los integration specs son type: :request, inyectamos el contexto por defecto:
  config.include_context "api_auth", type: :request
end