require "test_helper"

class SocialSignInTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup { OmniAuth.config.test_mode = true }

  teardown do
    OmniAuth.config.mock_auth.delete(:google)
    OmniAuth.config.mock_auth.delete(:github)
    OmniAuth.config.mock_auth.delete(:slack)
    OmniAuth.config.test_mode = false
  end

  test "login and sign-up pages offer Google and GitHub" do
    get "/users/login"
    assert_select "form[action='/users/auth/google'] button", text: /Continue with Google/
    assert_select "form[action='/users/auth/github'] button", text: /Continue with GitHub/

    get "/users/create-account"
    assert_select "form[action='/users/auth/github']"
  end

  test "signing up with GitHub creates a verified account and prefills onboarding" do
    mock(:github, uid: "42", email: "octo@example.com",
      info: {name: "Octo Cat", nickname: "octocat", urls: {"GitHub" => "https://github.com/octocat"}})

    assert_difference -> { User.count } => 1, -> { User::Identity.count } => 1 do
      sign_in_with(:github)
    end

    user = User.find_by!(email: "octo@example.com")
    assert user.verified?
    assert_enqueued_email_with Rodauth::UserMailer, :welcome, args: [:user, user.id]
    assert_equal %w[github 42], [user.identities.sole.provider, user.identities.sole.uid]

    follow_redirect! while response.redirect?
    assert_equal "/onboarding", path
    assert_select "input[name='onboarding[first_name]'][value='Octo']"
    assert_select "input[name='onboarding[other_names]'][value='Cat']"
    assert_select "input[value='octocat']"

    post "/onboarding", params: {onboarding: {developer: "1", first_name: "Octo", other_names: "Cat", handle: "octocat", hiring: "0"}}
    assert_equal "https://github.com/octocat", user.reload.developer_profile.github_url
  end

  test "Google sign-in links to an existing account with the same verified email" do
    user = create_user!(email: "ada@example.com")
    mock(:google, uid: "g-1", email: "ada@example.com", info: {name: "Ada"}, extra: {raw_info: {email_verified: true}})

    assert_no_difference -> { User.count } do
      assert_no_enqueued_emails { sign_in_with(:google) }
    end
    assert_equal user.id, User::Identity.find_by!(provider: "google", uid: "g-1").user_id
  end

  test "social sign-in that verifies an unverified account welcomes the user" do
    user = User.create!(email: "grace@example.com", status: :unverified)
    mock(:github, uid: "7", email: "grace@example.com")

    sign_in_with(:github)

    assert user.reload.verified?
    assert_enqueued_email_with Rodauth::UserMailer, :welcome, args: [:user, user.id]
  end

  test "an unverified Google email is refused" do
    create_user!(email: "victim@example.com")
    mock(:google, uid: "g-2", email: "victim@example.com", extra: {raw_info: {email_verified: false}})

    assert_no_difference -> { User::Identity.count } do
      sign_in_with(:google)
    end
    assert_redirected_to "/users/login"
  end

  test "login and sign-up pages offer Slack" do
    get "/users/login"
    assert_select "form[action='/users/auth/slack'] button", text: /Continue with Slack/
  end

  test "signing up with Slack creates a verified account" do
    mock_slack(uid: "U123", email: "ama@example.com", info: {name: "Ama Mensah", image: "https://avatars.slack-edge.com/ama.png"})

    assert_difference -> { User.count } => 1 do
      sign_in_with(:slack)
    end

    user = User.find_by!(email: "ama@example.com")
    assert user.verified?
    identity = user.identities.sole
    assert_equal %w[slack U123], [identity.provider, identity.uid]
    assert_equal "Ama Mensah", identity.info["name"]
    assert_not user.wants_notification?(:network, via: :email)
  end

  test "Slack sign-in from another workspace is refused" do
    mock_slack(uid: "U999", email: "someone@example.com", team: "T0OTHER")

    assert_no_difference -> { User.count } do
      sign_in_with(:slack)
    end
    assert_redirected_to "/users/login"
    follow_redirect!
    assert_select "#pu-flash", text: /That isn't the DevCongress Slack workspace\./
  end

  test "Slack sign-in without a team_id claim is refused" do
    mock(:slack, uid: "U997", email: "someone@example.com", extra: {raw_info: {"email_verified" => true}})

    assert_no_difference [-> { User.count }, -> { User::Identity.count }] do
      sign_in_with(:slack)
    end
    assert_redirected_to "/users/login"
    follow_redirect!
    assert_select "#pu-flash", text: /That isn't the DevCongress Slack workspace\./
  end

  test "an unverified Slack email is refused" do
    create_user!(email: "victim@example.com")
    mock_slack(uid: "U998", email: "victim@example.com", email_verified: false)

    assert_no_difference -> { User::Identity.count } do
      sign_in_with(:slack)
    end
    assert_redirected_to "/users/login"
  end

  test "Slack sign-in can't add a second Slack account by email" do
    user = create_user!(email: "ama@example.com")
    user.identities.create!(provider: "slack", uid: "U1")
    mock_slack(uid: "U2", email: "ama@example.com")

    assert_no_difference -> { User::Identity.count } do
      sign_in_with(:slack)
    end
    assert_redirected_to "/users/login"
    follow_redirect!
    assert_select "#pu-flash", text: /That email's account is already connected to a different Slack account\./
  end

  test "Slack sign-in links by email when the account has no Slack account" do
    user = create_user!(email: "ama@example.com")
    user.identities.create!(provider: "github", uid: "42")
    mock_slack(uid: "U2", email: "ama@example.com")

    assert_difference -> { user.identities.where(provider: "slack").count } => 1 do
      sign_in_with(:slack)
    end
  end

  private

  def mock(provider, uid:, email:, info: {}, extra: {})
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
      provider: provider.to_s, uid:, info: {email:}.merge(info), extra:
    )
  end

  def mock_slack(uid:, email:, team: "T0DEVCON", email_verified: true, info: {})
    mock(:slack, uid:, email:, info:, extra: {raw_info: {"https://slack.com/team_id" => team, "email_verified" => email_verified}})
  end

  # Request phase (POST, CSRF-checked) then the provider's callback.
  def sign_in_with(provider)
    post "/users/auth/#{provider}"
    follow_redirect!
  end
end
