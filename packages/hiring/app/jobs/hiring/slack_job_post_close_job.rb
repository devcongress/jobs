module Hiring
  # Closes the #jobs message of a job that was deleted while live. The job is
  # gone by now, so it gets the message's ts and closed rendering as values
  # (see JobPost#render_slack_close).
  class SlackJobPostCloseJob < ApplicationJob
    queue_as :default

    # Config problems (bad token, bot not in the channel...) won't fix
    # themselves.
    discard_on Slack::Error do |job, error|
      Rails.logger.error { "Closing #jobs message #{job.arguments.first[:ts]} failed: #{error.code}" }
    end
    # rescue_from RateLimited must come after discard_on Slack::Error so it takes precedence.
    rescue_from(Slack::RateLimited) { |error| retry_job(wait: error.retry_after.seconds) }
    retry_on(*Slack::NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)

    def perform(ts:, text:, blocks:)
      Slack.client.update_message(channel: Slack.jobs_channel, ts:, text:, blocks:)
    rescue Slack::Error => error
      # Already deleted in Slack: nothing left to close.
      raise unless error.code == "message_not_found"
    end
  end
end
