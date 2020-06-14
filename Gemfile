# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'puma'

gem 'rails', '~> 5.2.2'
gem 'sass-rails', '~> 5.0'
# gem 'sass', '~> 3.4', '>= 3.4.22'
# gem 'sassc', '~> 2.0', '>= 2.0.1'
gem 'sprockets', '~> 3.7', '>= 3.7.2'
gem 'uglifier', '>= 1.3.0'

gem 'coffee-rails', '~> 4.2'
gem 'jbuilder', '~> 2.5'
gem 'turbolinks', '~> 5'

gem 'bootsnap', '~> 1.3', require: false

gem 'devise', '~> 4.4', '>= 4.4.3'
gem 'oauth'
gem 'omniauth-google-oauth2'
gem 'sendgrid', '~> 1.2', '>= 1.2.4'
gem 'twitter', '~> 6.2'

gem 'pg'
gem 'sentry-raven'
gem 'trix'

gem 'jwt'

group :development, :test do
  gem 'awesome_print'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'factory_bot_rails'
end

group :development do
  gem 'annotate'
  gem 'figaro'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'faker'
  gem 'minitest-matchers_vaccine'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers'
  gem 'webdrivers'
end

group :production do
  gem 'rails_12factor'
  gem 'skylight'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
