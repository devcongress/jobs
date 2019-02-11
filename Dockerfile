FROM ruby:2.3.3

# Install basic packages
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

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