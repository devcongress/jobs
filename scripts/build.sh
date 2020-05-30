#!/bin/bash

set -e

echo ":: rebuilding containers"
docker-compose build --no-cache

echo ":: applying migrations and seeding database"
docker-compose run --rm web bundle exec rake db:migrate db:seed

echo ":: complete!!!"
