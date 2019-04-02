require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dcjobs
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # enabling rails assest pipleline on heroku for rails 4+. Can't believe I had missed this all this time along.
    config.public_file_server.enabled = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.active_record.schema_format = :sql

    config.filter_parameters << :password
    
    # Raven.configure do |config|
    #   config.dsn = 'https://f3bcfcf98aac4331b3df9af207507b4f:fc1a39e637804bf18c583f0dfa3bcbfd@sentry.io/1422368'
    # end
  end
end