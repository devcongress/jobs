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

### Build

On first install, you will need to run a build to setup any dependencies and get you started.

Any application code changes are automatically reloaded, however, changes to certain files e.g. [Dockerfile](./Dockerfile) require a build.

#### Linux/Mac

- `./scripts/build.sh`

#### Others

- `docker-compose build --no-cache`: rebuild containers
- `docker-compose run --rm web bundle exec rails db:migrate db:seed`: apply migrations and seed the database

### Run

#### Linux/Mac

- `./scripts/start.sh`

#### Others

- `docker-compose up --build`: build and start containers

If you'd rather run it in the background,

- `docker-compose up --build -d`: build and start containers in detached mode

## Develop

The application runs at http://localhost:3000/

> You can login with the default user created during seeding
>
> - email: test@example.com
> - password: password1

### Helpful Commands

- `docker-compose stop`: stop the running containers.
- `docker-compose start`: start stopped containers.
- `docker-compose down`: stop and remove containers and networks. you will need to recreate them using `up`

> **NOTE**: all `docker-compose` commands should be run from the project directory

> **TIP**: To remove any persisted data, delete the [.volumes](./.volumes) directory.

### Migrations

- `docker-compose stop`: stop any running containers to prevent contention over database files
- `docker-compose run --rm web bundle exec rails db:migrate`: apply migrations

### Seeding

- `docker-compose stop`: stop any running containers to prevent contention over database files
- `docker-compose run --rm web bundle exec rails db:seed`: seed database

## Testing

- `docker-compose stop`: stop any running containers to prevent contention over database files
- `docker-compose run --rm web bundle exec rails test`: run tests

## Troubleshooting

For consistency sake, be using the latest stable versions of `docker-compose` and `docker`

**Linux**

Scenario: `ERROR: Couldn't connect to Docker daemon at http+docker://localhost - is it running?`

Solution: Run `sudo usermod -aG docker ${USER}`. [More details](https://medium.com/@ibrahimgunduz34/if-you-faced-an-issue-like-couldnt-connect-to-docker-daemon-at-http-docker-localunixsocket-is-27b35f17d09d)
