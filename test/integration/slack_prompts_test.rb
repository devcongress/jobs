require "test_helper"

class SlackPromptsTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include SlackSignInTestHelper

  setup do
    ENV["SLACK_INVITE_URL"] = "https://join.slack.com/t/devcongress/shared_invite/abc"
    @profile = create_profile!(visibility: :everyone)
    @user = @profile.user
  end

  teardown { ENV.delete("SLACK_INVITE_URL") }

  test "the dashboard invites users without Slack" do
    login_user(@user)
    get "/dashboard"
    assert_select "[data-controller='dismiss'][data-dismiss-cookie-value='slack_prompt_dismissed']" do
      assert_select "a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /Join Slack/
      assert_select "button[data-action='dismiss#dismiss']"
    end
  end

  test "the card stays hidden once dismissed or connected" do
    login_user(@user)
    cookies[:slack_prompt_dismissed] = "1"
    get "/dashboard"
    assert_select "[data-controller='dismiss']", 0

    cookies.delete(:slack_prompt_dismissed)
    @user.identities.create!(provider: "slack", uid: "U1")
    get "/dashboard"
    assert_select "[data-controller='dismiss']", 0
  end

  test "the card is shown with only an invite link or only Slack sign-in" do
    login_user(@user)
    without_slack_sign_in { get "/dashboard" }
    assert_select "[data-controller='dismiss']", 1
    assert_select "form[action='/users/auth/slack']", 0

    ENV.delete("SLACK_INVITE_URL")
    get "/dashboard"
    assert_select "[data-controller='dismiss'] form[action='/users/auth/slack']", 1
  end

  test "no card when Slack isn't set up" do
    ENV.delete("SLACK_INVITE_URL")
    login_user(@user)
    without_slack_sign_in { get "/dashboard" }
    assert_response :success
    assert_select "[data-controller='dismiss']", 0
  end

  test "the footer links to Slack" do
    get "/"
    assert_select "footer a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /slack/i
  end

  test "linked profiles show a Slack badge" do
    @user.identities.create!(provider: "slack", uid: "U123")
    get "/@#{@profile.handle}"
    assert_select "a[href='https://devcongress-community.slack.com/team/U123']"
  end
end
