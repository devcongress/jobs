require "test_helper"

class Hiring::SlackJobPostSyncJobTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  setup do
    @company = create_company!(name: "Acme")
    @job = create_job!(company: @company)
    clear_enqueued_jobs
  end

  def sync = Hiring::SlackJobPostSyncJob.perform_now(@job.reload)

  test "an active job is posted and remembered" do
    sync

    post = @slack.calls_to(:post_message).sole
    assert_equal "C0JOBS", post.params[:channel]
    @job.reload
    assert_equal "active", @job.slack_posted_status
    assert_equal "1700000000.000001", @job.slack_message_ts
    assert_equal "https://devcongress-community.slack.com/archives/C0JOBS/p1700000000000001", @job.slack_message_url
  end

  test "edits to a live job update the message" do
    sync
    @job.update!(title: "Lead Engineer")
    sync

    update = @slack.calls_to(:update_message).sole
    assert_equal "1700000000.000001", update.params[:ts]
    assert_match "Lead Engineer", update.params[:text]
    assert_equal 1, @slack.calls_to(:post_message).size
  end

  test "filling, expiring and archiving close the message" do
    sync
    @job.mark_filled!
    sync
    assert_match "Filled", @slack.calls_to(:update_message).last.params[:text]
    assert_equal "filled", @job.reload.slack_posted_status

    other = create_job!(company: @company, title: "Other")
    Hiring::SlackJobPostSyncJob.perform_now(other)
    other.update_columns(expires_at: 1.minute.ago)
    Hiring::SlackJobPostSyncJob.perform_now(other.reload)
    assert_equal "expired", other.reload.slack_posted_status
  end

  test "a declined job is withdrawn" do
    sync
    @job.decline!("Needs a salary")
    sync
    assert_match "No longer available", @slack.calls_to(:update_message).last.params[:blocks].first.dig(:text, :text)
    assert_equal "withdrawn", @job.reload.slack_posted_status
  end

  test "reopening reposts and keeps the old message closed" do
    sync
    @job.mark_filled!
    sync
    @job.reopen!
    sync

    assert_equal 2, @slack.calls_to(:post_message).size
    assert_equal "1700000000.000002", @job.reload.slack_message_ts
    assert_equal "active", @job.slack_posted_status
  end

  test "drafts and closed jobs without a message are left alone" do
    draft = create_job!(company: @company, published: false)
    Hiring::SlackJobPostSyncJob.perform_now(draft)
    @job.mark_filled!
    sync
    assert_empty @slack.calls
  end

  test "a message deleted in Slack is reposted" do
    sync
    @slack.fail_next(:update_message, "message_not_found")
    @job.update!(title: "Lead Engineer")
    sync

    assert_equal 2, @slack.calls_to(:post_message).size
    assert_equal "1700000000.000002", @job.reload.slack_message_ts
  end

  test "a deleted message for a closed job is forgotten" do
    sync
    @slack.fail_next(:update_message, "message_not_found")
    @job.mark_filled!
    sync

    assert_nil @job.reload.slack_message_ts
    assert_nil @job.slack_posted_status
  end

  test "a permalink failure doesn't cause a duplicate post" do
    @slack.fail_next(:permalink, "internal_error")
    sync
    assert_equal "1700000000.000001", @job.reload.slack_message_ts
    assert_nil @job.slack_message_url
    assert_equal 1, @slack.calls_to(:post_message).size

    @job.update!(title: "Lead Engineer")
    sync
    assert_equal 1, @slack.calls_to(:post_message).size
    assert_equal "https://devcongress-community.slack.com/archives/C0JOBS/p1700000000000001", @job.reload.slack_message_url
  end

  test "config errors are discarded" do
    @slack.fail_next(:post_message, "channel_not_found")
    assert_nothing_raised { sync }
    assert_nil @job.reload.slack_message_ts
  end

  test "a job deleted before the sync runs is discarded" do
    Hiring::SlackJobPostSyncJob.perform_later(@job)
    @job.delete
    assert_nothing_raised { perform_enqueued_jobs(only: Hiring::SlackJobPostSyncJob) }
    assert_empty @slack.calls
  end

  test "saving a job enqueues a sync when relevant fields change" do
    assert_enqueued_with(job: Hiring::SlackJobPostSyncJob, args: [@job]) { @job.update!(title: "New title") }
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostSyncJob) { @job.update!(apply_url: "https://acme.example/jobs") }
  end

  test "nothing is enqueued when Slack isn't set up" do
    Slack.client = nil
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostSyncJob) { @job.update!(title: "New title") }
  end
end
