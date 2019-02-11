#!/bin/bash

echo "~~~~~> creating containers"
docker-compose up --build -d

echo "~~~~~> waiting for containers to start"
# elegant but inefficient. we wait a few seconds
secs=5
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done

echo "~~~~~> applying migrations and seeding database"
docker-compose run --rm web rake db:migrate db:seed

echo "complete!!!"
