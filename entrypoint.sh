#!/bin/bash

gem install bundler
bundle install --binstubs="$BUNDLE_BIN"

exec "$@"