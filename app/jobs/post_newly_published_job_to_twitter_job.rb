class PostNewlyPublishedJobToTwitterJob < ApplicationJob
  queue_as :default

  def perform(job)
    twitter_client = TwitterClient.new(
      consumer_key: ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
      access_token: ENV['TWITTER_ACCESS_TOKEN'],
      access_token_secret: ENV['TWITTER_ACCESS_SECRET']
    )
    twitter_client.post_job_link job
  end
end
