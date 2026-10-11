require "test_helper"

class UserSlackTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup do
    @user = create_user!
  end

  def link_slack(user = @user) = user.identities.create!(provider: "slack", uid: "U#{SecureRandom.hex(3)}", info: {"name" => "Ama Mensah"})

  test "slack_identity" do
    assert_nil @user.slack_identity
    identity = link_slack
    assert_equal identity, @user.slack_identity
  end

  test "connecting Slack turns email off for every category" do
    @user.slack_connected!
    NotificationOptOut::CATEGORIES.each_key do |category|
      assert_not @user.wants_notification?(category, via: :email)
      assert @user.wants_notification?(category, via: :slack)
    end
  end

  test "disconnecting brings email back where Slack was on" do
    link_slack
    @user.slack_connected!
    @user.opt_out!(:network, via: :slack)

    @user.disconnect_slack!

    assert_nil @user.reload.slack_identity
    assert @user.wants_notification?(:applications, via: :email)
    assert @user.wants_notification?(:project_credits, via: :email)
    assert_not @user.wants_notification?(:network, via: :email)
  end

  test "Slack is the only sign-in without a password or another identity" do
    passwordless = User.create!(email: "nopass@example.com", status: :verified)
    link_slack(passwordless)
    assert_not passwordless.can_sign_in_without_slack?

    passwordless.identities.create!(provider: "github", uid: "1")
    assert passwordless.can_sign_in_without_slack?
    assert @user.can_sign_in_without_slack?
  end
end
