[![Build Status](https://travis-ci.org/devcongress/jobs.svg?branch=master)](https://travis-ci.org/devcongress/jobs)
[![View performance data on Skylight](https://badges.skylight.io/problem/H0Z1ot94WfYy.svg?token=aEuput--iL0JhxpDYjv25vjvdh3cZcO4gb5gPYZIDKg)](https://www.skylight.io/app/applications/H0Z1ot94WfYy)
[![View performance data on Skylight](https://badges.skylight.io/typical/H0Z1ot94WfYy.svg?token=aEuput--iL0JhxpDYjv25vjvdh3cZcO4gb5gPYZIDKg)](https://www.skylight.io/app/applications/H0Z1ot94WfYy)
[![View performance data on Skylight](https://badges.skylight.io/rpm/H0Z1ot94WfYy.svg?token=aEuput--iL0JhxpDYjv25vjvdh3cZcO4gb5gPYZIDKg)](https://www.skylight.io/app/applications/H0Z1ot94WfYy)
[![View performance data on Skylight](https://badges.skylight.io/status/H0Z1ot94WfYy.svg?token=aEuput--iL0JhxpDYjv25vjvdh3cZcO4gb5gPYZIDKg)](https://www.skylight.io/app/applications/H0Z1ot94WfYy)

# DevCongress Jobs

This is the code which runs the DevCongress Jobs website, which lives at [jobs.devcongress.org](http://jobs.devcongress.org)

## Docker setup

### Requirements

[Install Docker and Docker Compose](https://docs.docker.com/v17.09/engine/installation/#supported-platforms) (Docker Compose comes with Docker on Windows and MacOS)

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

## Troubleshooting

For consistency sake, be using the latest stable versions of `docker-compose` and `docker`

**Linux**

Scenario: `ERROR: Couldn't connect to Docker daemon at http+docker://localhost - is it running?`

Solution: Run `sudo usermod -aG docker ${USER}`. [More details](https://medium.com/@ibrahimgunduz34/if-you-faced-an-issue-like-couldnt-connect-to-docker-daemon-at-http-docker-localunixsocket-is-27b35f17d09d)
