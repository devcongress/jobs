module Slack
  # The few Web API methods we use, called with the bot token.
  class Client
    BASE_URL = "https://slack.com/api/"

    def initialize(token)
      @token = token
    end

    def post_message(channel:, text:, blocks: nil)
      call("chat.postMessage", channel:, text:, blocks:, unfurl_links: false)
    end

    def update_message(channel:, ts:, text:, blocks: nil)
      call("chat.update", channel:, ts:, text:, blocks:)
    end

    def permalink(channel:, ts:)
      call("chat.getPermalink", channel:, message_ts: ts).fetch("permalink")
    end

    private

    def call(method, **params)
      params[:blocks] = params[:blocks].to_json if params[:blocks]
      response = http_post(URI("#{BASE_URL}#{method}"), URI.encode_www_form(params.compact),
        "Authorization" => "Bearer #{@token}", "Content-Type" => "application/x-www-form-urlencoded")
      raise RateLimited.new((response["Retry-After"] || 30).to_i) if response.code == "429"
      raise Unavailable, "Slack returned #{response.code}" if response.code.start_with?("5")

      body = JSON.parse(response.body)
      raise Error.new(body["error"]) unless body["ok"]

      body
    end

    def http_post(uri, form, headers)
      Net::HTTP.post(uri, form, headers)
    end
  end
end
