require "test_helper"

class SlackJobsTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  setup do
    @job = create_job!(company: create_company!)
  end

  test "a job posted to Slack links to its thread" do
    @job.update_columns(slack_message_ts: "1.1", slack_message_url: "https://devcongress-community.slack.com/archives/C0JOBS/p11")
    get "/jobs/#{@job.to_param}"
    assert_select "a[href='https://devcongress-community.slack.com/archives/C0JOBS/p11']", /Discuss in #jobs/
  end

  test "no Slack link without a message" do
    get "/jobs/#{@job.to_param}"
    assert_select "a", text: /Discuss in #jobs/, count: 0
  end

  test "signed-out visitors are invited to join Slack" do
    ENV["SLACK_INVITE_URL"] = "https://join.slack.com/t/devcongress/shared_invite/abc"
    get "/jobs/#{@job.to_param}"
    assert_select "a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /Join the DevCongress Slack/
  ensure
    ENV.delete("SLACK_INVITE_URL")
  end
end
