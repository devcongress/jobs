require "test_helper"

class SlackConnectionTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = create_profile!.user
  end

  teardown do
    OmniAuth.config.mock_auth.delete(:slack)
    OmniAuth.config.test_mode = false
  end

  test "connecting Slack while signed in links it to you and turns email off" do
    login_user(@user)
    mock_slack(uid: "U123", email: "different@example.com")

    assert_no_difference -> { User.count } do
      post "/users/auth/slack"
      follow_redirect!
    end

    assert_redirected_to "/dashboard/settings/notifications"
    assert_equal "U123", @user.reload.slack_identity.uid
    assert_not @user.wants_notification?(:applications, via: :email)
    follow_redirect! while response.redirect?
    assert_equal "/dashboard/settings/notifications", path
    assert_select "#pu-flash", text: /Slack connected/
  end

  test "a Slack account linked to someone else can't be connected" do
    other = create_user!
    other.identities.create!(provider: "slack", uid: "U123")
    login_user(@user)
    mock_slack(uid: "U123", email: @user.email)

    post "/users/auth/slack"
    follow_redirect!

    assert_nil @user.reload.slack_identity
    assert_equal other.id, User::Identity.find_by!(provider: "slack", uid: "U123").user_id
    assert_redirected_to "/dashboard/settings/notifications"
    follow_redirect!
    assert_response :success
    assert_select "#pu-flash", text: /connected to another DevCongress Connect account/
  end

  test "disconnecting" do
    @user.identities.create!(provider: "slack", uid: "U123")
    @user.slack_connected!
    login_user(@user)

    delete "/dashboard/settings/slack"

    assert_redirected_to "/dashboard/settings/notifications"
    assert_nil @user.reload.slack_identity
    assert @user.wants_notification?(:applications, via: :email)
  end

  test "can't disconnect the only way to sign in" do
    user = User.create!(email: "slackonly@example.com", status: :verified)
    create_profile!(user:)
    # No password, so sign in with Slack (links U555 by verified email).
    mock_slack(uid: "U555", email: user.email)
    post "/users/auth/slack"
    follow_redirect! while response.redirect?

    delete "/dashboard/settings/slack"

    assert_redirected_to "/dashboard/settings/notifications"
    assert_equal "U555", user.reload.slack_identity.uid
    follow_redirect!
    assert_response :success
    assert_select "#pu-flash", text: /Set a password first/
  end

  test "a second Slack account can't be connected" do
    @user.identities.create!(provider: "slack", uid: "U123")
    login_user(@user)
    mock_slack(uid: "U456", email: @user.email)

    assert_no_difference -> { User::Identity.count } do
      post "/users/auth/slack"
      follow_redirect!
    end

    assert_redirected_to "/dashboard/settings/notifications"
    assert_equal "U123", @user.reload.slack_identity.uid
    assert @user.wants_notification?(:applications, via: :email)
    assert_equal "Disconnect your current Slack account first.", flash[:alert]
  end

  test "connecting Slack from another workspace while signed in is refused" do
    login_user(@user)
    mock_slack(uid: "U123", email: @user.email, team: "T0OTHER")

    post "/users/auth/slack"
    follow_redirect!

    assert_nil @user.reload.slack_identity
    assert @user.wants_notification?(:applications, via: :email)
  end

  test "connecting Slack with an unverified email while signed in is refused" do
    login_user(@user)
    mock_slack(uid: "U123", email: @user.email, email_verified: false)

    post "/users/auth/slack"
    follow_redirect!

    assert_nil @user.reload.slack_identity
    assert @user.wants_notification?(:applications, via: :email)
  end

  test "reconnecting your own Slack account changes nothing" do
    @user.identities.create!(provider: "slack", uid: "U123")
    login_user(@user)
    mock_slack(uid: "U123", email: @user.email)

    assert_no_difference -> { User::Identity.count } do
      post "/users/auth/slack"
      follow_redirect!
    end

    assert_equal "U123", @user.reload.slack_identity.uid
    assert @user.wants_notification?(:applications, via: :email)
    assert_nil flash[:alert]
  end

  test "disconnecting when Slack isn't connected" do
    login_user(@user)

    delete "/dashboard/settings/slack"

    assert_redirected_to "/dashboard/settings/notifications"
    assert_equal "Slack isn't connected.", flash[:notice]
  end

  private

  def mock_slack(uid:, email:, team: "T0DEVCON", email_verified: true)
    OmniAuth.config.mock_auth[:slack] = OmniAuth::AuthHash.new(
      provider: "slack", uid:, info: {email:, name: "Ama Mensah"},
      extra: {raw_info: {"https://slack.com/team_id" => team, "email_verified" => email_verified}}
    )
  end
end
