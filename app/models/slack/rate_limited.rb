module Slack
  class RateLimited < Error
    attr_reader :retry_after

    def initialize(retry_after)
      @retry_after = retry_after
      super("ratelimited")
    end
  end
end
