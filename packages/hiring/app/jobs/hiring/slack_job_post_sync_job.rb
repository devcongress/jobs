module Hiring
  # Makes a job's #jobs message match the job. It renders from the job's
  # current state, so running it twice is harmless. slack_posted_status
  # records what the message shows now.
  class SlackJobPostSyncJob < ApplicationJob
    queue_as :default
    limits_concurrency to: 1, key: ->(job_post) { job_post }

    # The job was deleted before the sync ran (SlackJobPostCloseJob closes it).
    discard_on ActiveJob::DeserializationError
    # Config problems (bad token, bot not in the channel...) won't fix
    # themselves.
    discard_on Slack::Error do |job, error|
      Rails.logger.error { "#jobs sync for job post #{job.arguments.first.id} failed: #{error.code}" }
    end
    # rescue_from RateLimited must come after discard_on Slack::Error so it takes precedence.
    rescue_from(Slack::RateLimited) { |error| retry_job(wait: error.retry_after.seconds) }
    retry_on(*Slack::NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)

    def perform(job_post)
      @job = job_post
      status = job_post.status.to_s

      if status == "active"
        (job_post.slack_posted_status == "active") ? update_message : post_message
      elsif job_post.slack_posted_status == "active"
        close_message(%w[draft pending_review].include?(status) ? "withdrawn" : status)
      end
    end

    private

    def post_message
      message = JobPostSlackMessage.new(@job)
      ts = client.post_message(channel:, text: message.text, blocks: message.blocks).fetch("ts")
      # Save the ts first so a permalink failure and retry can't post twice.
      @job.update_columns(slack_message_ts: ts, slack_posted_status: "active")
      @job.update_columns(slack_message_url: client.permalink(channel:, ts:))
    end

    def update_message
      edit(JobPostSlackMessage.new(@job))
      @job.update_columns(slack_message_url: client.permalink(channel:, ts: @job.slack_message_ts)) if @job.slack_message_url.blank? && @job.slack_message_ts
    end

    def close_message(closed_as)
      # edit returns false when the message was gone, so the status isn't written.
      edit(JobPostSlackMessage.new(@job, closed_as:)) && @job.update_columns(slack_posted_status: closed_as)
    end

    # Updates the message in place. If it was deleted in Slack, forget it,
    # and post a fresh one when the job is live.
    def edit(message)
      client.update_message(channel:, ts: @job.slack_message_ts, text: message.text, blocks: message.blocks)
    rescue Slack::Error => error
      raise unless error.code == "message_not_found"

      @job.update_columns(slack_message_ts: nil, slack_message_url: nil, slack_posted_status: nil)
      post_message if @job.active?
      false
    end

    def client = Slack.client

    def channel = Slack.jobs_channel
  end
end
