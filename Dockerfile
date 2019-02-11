FROM ruby:2.3.3

# Install basic packages
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

# rake postgres dependencies
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.5" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update
# libpq-dev is required for the pg gem
RUN apt-get install -y libpq-dev postgresql-client-9.5

# Make app dir
RUN mkdir /app
WORKDIR /app

# Import Gemfile
COPY Gemfile Gemfile.lock ./

EXPOSE 3000
ENV RAILS_ENV=development

# Import entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bundle", "exec", "rails s -p 3000 -b 0.0.0.0"]

ENV BUNDLE_PATH=/bundle \
    BUNDLE_BIN=/bundle/bin \
    GEM_HOME=/bundle \
    BUNDLE_JOBS=4
ENV PATH="${GEM_HOME}/:${PATH}"