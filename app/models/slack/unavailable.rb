module Slack
  # Slack answered with a 5xx, usually an HTML error page rather than JSON.
  class Unavailable < StandardError
  end
end
