[![Build Status](https://travis-ci.org/devcongress/jobs.svg?branch=master)](https://travis-ci.org/devcongress/jobs)

# DevCongress Jobs

This is the code which runs the DevCongress Jobs website, which lives at [jobs.devcongress.org](http://jobs.devcongress.org)

## Docker setup

### Requirements

Install Docker and Docker Compose (Docker Compose comes with Docker on Windows and MacOS)

### Start Project

Launch docker with `docker-compose up`

### Manually running migrations

This should not be necessary on project start, but during development you can use it to run newer migrations

```sh
docker-compose  run --rm web rake db:create db:migrate db:seed
```