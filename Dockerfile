# Base our image on an official, minimal image of our preferred Ruby
FROM ruby:2.3.3

# Install essential Linux packages
# RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql-client

# Define where our application will live inside the image
ENV APP_HOME /JOBS

# Installation of dependencies
RUN apt-get update -qq \
  && apt-get install -y \
      # Needed for certain gems
    build-essential \
      # Needed for postgres gem
    libpq-dev \
    # The following are used to trim down the size of the image by removing unneeded data
  && apt-get clean autoclean \
  && apt-get autoremove -y \
  && rm -rf \
    /var/lib/apt \
    /var/lib/dpkg \
    /var/lib/cache \
    /var/lib/log

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir $APP_HOME

# Set our working directory inside the image
WORKDIR $APP_HOME

# Add our Gemfile and install gems
ADD Gemfile* $APP_HOME/

# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
RUN gem install bundler

# Finish establishing our Ruby enviornment
RUN bundle install

# Copy the Rails application into place
ADD . $APP_HOME

# Run our app
CMD RAILS_ENV=${RAILS_ENV} bundle exec rails db:create db:migrate db:seed && bundle exec rails s -p ${PORT} -b '0.0.0.0'