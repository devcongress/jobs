[![Build Status](https://travis-ci.org/devcongress/jobs.svg?branch=master)](https://travis-ci.org/devcongress/jobs)

# DevCongress Jobs

This is the code which runs the DevCongress Jobs website, which lives at [jobs.devcongress.org](http://jobs.devcongress.org)

## Docker setup

### Requirements

Install Docker and Docker Compose (Docker Compose comes with Docker on Windows and MacOS)

### Run Project

Run `./scripts/create.sh` if on linux.

Otherwise,
- run `docker-compose up --build -d` to start the containers
- run `docker-compose run --rm web rake db:migrate db:seed` to apply migrations and seed the database

You can now log in with the default user that was created during the seeding

```
email: test@example.com
password: password1
```

## Migrations

To apply new database changes, run 
- `docker-compose run --rm web rake db:migrate`

## Seeding

To seed the database, run 
- `docker-compose run --rm web rake db:seed`
