source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'rails', '~> 5.2.2'
gem 'pg'   # Database (PostgreSQL)
gem 'puma' # Web server (https://puma.io/)

gem 'sass-rails', '~> 5.0'
gem 'sprockets', '~> 3.7', '>= 3.7.2'
gem 'uglifier', '>= 1.3.0'

gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'

gem 'bootsnap', '~> 1.3', require: false

gem 'devise', '~> 4.4', '>= 4.4.3'
gem 'sendgrid', '~> 1.2', '>= 1.2.4'
gem 'twitter', '~> 6.2'
gem 'oauth'
gem 'omniauth-google-oauth2'

gem 'trix'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
  gem 'dotenv-rails'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'annotate'
  gem "figaro"
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'minitest-matchers_vaccine'

  # Danger (https://danger.systems/ruby/) runs during your CI process, and gives
  # teams the chance to automate common code review chores. See Dangerfile for
  # rules that will automatically fail a PR.
  gem 'danger'
end

group :production do
  # Automated exception reporting using the Sentry service (https://sentry.io/)
  # We intentionally don't pin a version (see Gemfile.lock for actual version)
  # because we want to stay on the latest. A breakage in Sentry doesn't break
  # the app.
  gem "sentry-raven"

  # We use Skylight (https://www.skylight.io/) for performance monitoring: everything
  # from a deep breakdown of where we spent time and did work while responding to a
  # request.
  gem 'skylight'

  # This gem enables serving assets in production and setting your logger to
  # standard out, both of which are required to run on a twelve-factor provider.
  gem 'rails_12factor'
end


gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
