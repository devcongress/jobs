require "test_helper"

class NotificationSettingsTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include SlackSignInTestHelper

  setup { @user = create_profile!.user }

  test "needs sign-in" do
    get "/dashboard/settings/notifications"
    assert_response :redirect
  end

  test "the old email settings path redirects" do
    login_user(@user)
    get "/dashboard/settings/email"
    assert_redirected_to "/dashboard/settings/notifications"
  end

  test "without Slack: email on, Slack column disabled, connect offered" do
    login_user(@user)
    get "/dashboard/settings/notifications"

    assert_response :success
    assert_select "input[type=checkbox][name='notification_settings[email][]'][checked]", 3
    assert_select "input[type=checkbox][name='notification_settings[slack][]'][disabled]", 3
    assert_select "form[action='/users/auth/slack'] button", /Connect Slack/
    assert_match "Connect Slack first", response.body
  end

  test "without Slack sign-in: no Slack card or column" do
    login_user(@user)
    without_slack_sign_in { get "/dashboard/settings/notifications" }

    assert_response :success
    assert_select "input[type=checkbox][name='notification_settings[email][]']", 3
    assert_select "input[name='notification_settings[slack][]']", 0
    assert_no_match "DevCongress lives on Slack", response.body
    assert_no_match "Connect Slack first", response.body
    assert_select "span", text: "Slack", count: 0
  end

  test "without Slack sign-in but with an invite link: card shown, no Slack column" do
    ENV["SLACK_INVITE_URL"] = "https://join.slack.com/t/devcongress/shared_invite/abc"
    login_user(@user)
    without_slack_sign_in { get "/dashboard/settings/notifications" }

    assert_select "a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /Join Slack/
    assert_select "input[name='notification_settings[slack][]']", 0
  ensure
    ENV.delete("SLACK_INVITE_URL")
  end

  test "connected users keep the Slack card and column without Slack sign-in" do
    @user.identities.create!(provider: "slack", uid: "U1")
    login_user(@user)
    without_slack_sign_in { get "/dashboard/settings/notifications" }

    assert_select "form[action='/dashboard/settings/slack'] button", /Disconnect/
    assert_select "input[type=checkbox][name='notification_settings[slack][]']:not([disabled])", 3
  end

  test "with Slack: connected card and both columns" do
    @user.identities.create!(provider: "slack", uid: "U1", info: {"name" => "Ama Mensah"})
    @user.slack_connected!
    login_user(@user)
    get "/dashboard/settings/notifications"

    assert_match "Connected as", response.body
    assert_match "Ama Mensah", response.body
    assert_select "form[action='/dashboard/settings/slack'] button", /Disconnect/
    assert_select "input[name='notification_settings[email][]'][checked]", 0
    assert_select "input[name='notification_settings[slack][]'][checked]", 3
  end

  test "saving updates both channels" do
    @user.identities.create!(provider: "slack", uid: "U1")
    login_user(@user)

    patch "/dashboard/settings/notifications", params: {notification_settings: {email: ["", "network"], slack: ["", "applications", "project_credits"]}}

    assert_redirected_to "/dashboard/settings/notifications"
    assert_equal %w[applications project_credits], @user.notification_opt_outs.where(channel: "email").pluck(:category).sort
    assert_equal %w[network], @user.notification_opt_outs.where(channel: "slack").pluck(:category)
  end

  test "saving without Slack leaves Slack opt-outs alone" do
    @user.opt_out!(:network, via: :slack)
    login_user(@user)

    patch "/dashboard/settings/notifications", params: {notification_settings: {email: ["", "network", "applications", "project_credits"]}}

    assert_not @user.wants_notification?(:network, via: :slack)
  end

  test "the user menu links to the page" do
    login_user(@user)
    get "/dashboard"
    assert_select "a[href='/dashboard/settings/notifications']", /Notification settings/
  end
end
