require "test_helper"

class SlackDmTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  class TestDm < SlackDm
    self.category = :network

    def recipient = params[:user]

    def text = "Hello"

    def blocks = [section("*Hello*")]
  end

  setup { @user = create_user! }

  test "delivers later through the job" do
    assert_enqueued_with(job: SlackDmJob, args: ["SlackDmTest::TestDm", {user: @user}]) do
      TestDm.new(user: @user).deliver_later
    end
  end

  test "does nothing when Slack isn't set up" do
    Slack.client = nil
    assert_no_enqueued_jobs { TestDm.new(user: @user).deliver_later }
  end

  test "skips users without Slack" do
    TestDm.new(user: @user).deliver_now
    assert_empty @slack.calls
  end

  test "skips users who turned the category off on Slack" do
    @user.identities.create!(provider: "slack", uid: "U1")
    @user.opt_out!(:network, via: :slack)
    TestDm.new(user: @user).deliver_now
    assert_empty @slack.calls
  end

  test "sends to the Slack user with the settings footer" do
    @user.identities.create!(provider: "slack", uid: "U1")
    SlackDmJob.perform_now("SlackDmTest::TestDm", user: @user)

    call = @slack.calls_to(:post_message).sole
    assert_equal "U1", call.params[:channel]
    assert_equal "Hello", call.params[:text]
    footer = call.params[:blocks].last
    assert_equal "context", footer[:type]
    token = NotificationOptOut.token_for(@user, :network, via: :slack)
    assert_match "/unsubscribe/#{token}|Turn off Slack DMs for network activity", footer[:elements].sole[:text]
    assert_match "/dashboard/settings/notifications|Notification settings", footer[:elements].sole[:text]
  end

  test "people who left the workspace are skipped with a warning" do
    @user.identities.create!(provider: "slack", uid: "U1")
    @slack.fail_next(:post_message, "user_not_found")
    log = capture_log { assert_nothing_raised { SlackDmJob.perform_now("SlackDmTest::TestDm", user: @user) } }
    assert_match(/WARN -- : .*not sent: user_not_found/, log)
  end

  test "config errors are discarded and logged as errors" do
    @user.identities.create!(provider: "slack", uid: "U1")
    @slack.fail_next(:post_message, "invalid_auth")
    log = capture_log { assert_nothing_raised { SlackDmJob.perform_now("SlackDmTest::TestDm", user: @user) } }
    assert_match(/ERROR -- : .*not sent: invalid_auth/, log)
  end

  private

  def capture_log
    io = StringIO.new
    logger = Rails.logger
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = logger
  end
end
