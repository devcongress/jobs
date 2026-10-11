module Slack
  class Error < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super("Slack API error: #{code}")
    end
  end
end
