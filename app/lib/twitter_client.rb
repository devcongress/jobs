class TwitterClient

    def initialize(consumer_key:, consumer_secret:, access_token:, access_token_secret:)
        @client = Twitter::REST::Client.new do |config|
            config.consumer_key        = consumer_key
            config.consumer_secret     = consumer_secret
            config.access_token        = access_token
            config.access_token_secret = access_token_secret
        end
    end

    def post_job_title job
        @client.update("This is a job title. #{job.title}")
    end

    def post_job_link job
        @client.update("New Job. Link at #{job.url}")
    end
end