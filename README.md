[![Build Status](https://travis-ci.org/devcongress/jobs.svg?branch=master)](https://travis-ci.org/devcongress/jobs)

# DevCongress Jobs

This is the code which runs the DevCongress Jobs website, which lives at [jobs.devcongress.org](http://jobs.devcongress.org)

## Docker setup

### Requirements

Install Docker and Docker Compose (Docker Compose comes with Docker on Windows and MacOS)

### Run Project

Run `./bin/create.sh` if on linux.

Otherwise,
- `docker-compose up --build -d`: build app image and start the containers in detached mode
- `docker-compose run --rm web rails db:migrate db:seed`: apply migrations and seed the database

> You can now log in with the default user that was created during the seeding
> - email: test@example.com
> - password: password1

Some helpful commands (all commands should be run from the project directory)
- `docker-compose stop`: stop the running containers.
- `docker-compose start`: start stopped containers.
- `docker-compose down`: stop and remove containers and networks. you will need to recreate them using `up`

> To remove any persisted data, delete the `.volumes` directory.

## Migrations

To apply new database changes, run 
- `docker-compose run --rm web rails db:migrate`

## Seeding

To seed the database, run 
- `docker-compose run --rm web rails db:seed`
