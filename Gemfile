source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.1'

gem 'puma'

gem 'rails', '~> 5.2.2'
gem 'sass-rails', '~> 5.0'
# gem 'sass', '~> 3.4', '>= 3.4.22'
# gem 'sassc', '~> 2.0', '>= 2.0.1'
gem 'sprockets', '~> 3.7', '>= 3.7.2'
gem 'uglifier', '>= 1.3.0'

gem 'coffee-rails', '~> 4.2'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'

gem 'bootsnap', '~> 1.3', require: false

gem 'devise', '~> 4.4', '>= 4.4.3'
gem 'sendgrid', '~> 1.2', '>= 1.2.4'
gem 'twitter', '~> 6.2'
gem 'oauth'

gem 'pg'
gem 'trix'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'annotate'
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'minitest-matchers_vaccine'
end

group :production do
  gem 'rails_12factor'
  gem 'skylight'
  # gem "sentry-raven"
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
