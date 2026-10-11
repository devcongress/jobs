require "test_helper"

class Hiring::SlackJobPostCloseJobTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  setup do
    @job = create_job!(company: create_company!(name: "Acme"))
    Hiring::SlackJobPostSyncJob.perform_now(@job)
    @job.reload
    clear_enqueued_jobs
  end

  test "deleting a live job closes its message" do
    perform_enqueued_jobs(only: Hiring::SlackJobPostCloseJob) { @job.destroy! }

    update = @slack.calls_to(:update_message).sole
    assert_equal "C0JOBS", update.params[:channel]
    assert_equal "1700000000.000001", update.params[:ts]
    assert_match "No longer available", update.params[:text]
    assert_match "No longer available", update.params[:blocks].first.dig(:text, :text)
  end

  test "deleting a job without a live message enqueues nothing" do
    @job.update_columns(slack_posted_status: "filled")
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostCloseJob) { @job.destroy! }

    draft = create_job!(company: @job.company, published: false)
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostCloseJob) { draft.destroy! }
  end

  test "nothing is enqueued when Slack isn't set up" do
    Slack.client = nil
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostCloseJob) { @job.destroy! }
  end

  test "a message already deleted in Slack is ignored" do
    @slack.fail_next(:update_message, "message_not_found")
    assert_nothing_raised do
      perform_enqueued_jobs(only: Hiring::SlackJobPostCloseJob) { @job.destroy! }
    end
  end

  test "config errors are discarded" do
    @slack.fail_next(:update_message, "channel_not_found")
    assert_nothing_raised do
      perform_enqueued_jobs(only: Hiring::SlackJobPostCloseJob) { @job.destroy! }
    end
  end
end
