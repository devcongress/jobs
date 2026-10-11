module Hiring
  # Jobs expire by time, so nothing saves them when they do. This closes their
  # #jobs messages (scheduled in config/recurring.yml).
  class SlackJobSweepJob < ApplicationJob
    queue_as :default

    def perform
      JobPost.where(slack_posted_status: "active").where(expires_at: ..Time.current).find_each do |job_post|
        SlackJobPostSyncJob.perform_later(job_post)
      end
    end
  end
end
