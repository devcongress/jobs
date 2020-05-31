#!/bin/bash

gem install bundler
bundle binstubs --all

if [[ "$@" == *"rails s"* ]]; then
  # only remove pid when running rails
  if [ -f /app/tmp/pids/server.pid ]; then
    rm /app/tmp/pids/server.pid
  fi
fi

exec "$@"