require "test_helper"

class Hiring::SlackJobSweepJobTest < ActiveJob::TestCase
  include AccountsTestHelper

  test "expired jobs still showing as live in Slack are synced" do
    company = create_company!
    expired = create_job!(company:, title: "Expired")
    expired.update_columns(expires_at: 1.hour.ago, slack_message_ts: "1.1", slack_posted_status: "active")
    live = create_job!(company:, title: "Live")
    live.update_columns(slack_message_ts: "1.2", slack_posted_status: "active")
    closed = create_job!(company:, title: "Already closed")
    closed.update_columns(expires_at: 1.hour.ago, slack_message_ts: "1.3", slack_posted_status: "expired")

    Hiring::SlackJobSweepJob.perform_now

    assert_enqueued_jobs 1, only: Hiring::SlackJobPostSyncJob
    assert_enqueued_with job: Hiring::SlackJobPostSyncJob, args: [expired]
  end
end
