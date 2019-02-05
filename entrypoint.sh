#!/bin/bash

gem install bundler
bundle install --binstubs="$BUNDLE_BIN"

if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

# taken from https://medium.com/@k.szromek/docker-tips-for-ruby-on-rails-apps-f1d2702a07df
bundle exec rake db:create db:migrate db:seed

if [[ $? != 0 ]]; then
  echo
  echo "== Failed to migrate. Running setup first."
  echo
  bundle exec rake db:setup
fi

exec "$@"