# Use this hook to configure the litestream-ruby gem.
# All configuration options will be available as environment variables, e.g.
# config.replica_bucket becomes LITESTREAM_REPLICA_BUCKET
# Litestream is configured from environment variables only,
# or some other mechanism where the values are only available at runtime.

Rails.application.configure do
  # Replica-specific bucket location. This will be your bucket's URL without the `https://` prefix.
  # For example, if you used DigitalOcean Spaces, your bucket URL could look like:
  #
  #   https://myapp.fra1.digitaloceanspaces.com
  #
  # And so you should set your `replica_bucket` to:
  #
  #   myapp.fra1.digitaloceanspaces.com
  #
  config.litestream.replica_bucket = ENV["LITESTREAM_REPLICA_BUCKET"]
  #
  # Replica-specific authentication key. Litestream needs authentication credentials to access your storage provider bucket.
  config.litestream.replica_key_id = ENV["LITESTREAM_ACCESS_KEY_ID"]
  #
  # Replica-specific secret key. Litestream needs authentication credentials to access your storage provider bucket.
  config.litestream.replica_access_key = ENV["LITESTREAM_SECRET_ACCESS_KEY"]
  #
  # Replica-specific region. Set the bucket’s region. Only used for AWS S3 & Backblaze B2.
  # config.litestream.replica_region = "us-east-1"
  #
  # Replica-specific endpoint. Set the endpoint URL of the S3-compatible service. Only required for non-AWS services.
  # config.litestream.replica_endpoint = "endpoint.your-objectstorage.com"

  # Configure the default Litestream config path
  # config.config_path = Rails.root.join("config", "litestream.yml")

  # Configure the Litestream dashboard
  #
  # Set the default base controller class
  # config.litestream.base_controller_class = "MyApplicationController"
  #
  # Set authentication credentials for Litestream dashboard
  config.litestream.username = ENV["LITESTREAM_USERNAME"]
  config.litestream.password = ENV["LITESTREAM_PASSWORD"]
end
