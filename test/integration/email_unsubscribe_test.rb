require "test_helper"

class EmailUnsubscribeTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  setup do
    @user = create_user!
    @token = NotificationOptOut.token_for(@user, :network, via: :email)
  end

  test "opening the link asks before turning anything off" do
    get "/unsubscribe/#{@token}"

    assert_response :success
    assert_select "h1", /Turn off network activity emails/
    assert @user.wants_notification?(:network, via: :email)
  end

  test "confirming turns the category off without signing in" do
    post "/unsubscribe/#{@token}"

    assert_response :success
    assert_select "h1", /won't get network activity emails/
    assert_not @user.wants_notification?(:network, via: :email)
    assert @user.wants_notification?(:applications, via: :email)
  end

  test "mail clients can unsubscribe in one click, without a CSRF token" do
    ActionController::Base.allow_forgery_protection = true
    post "/unsubscribe/#{@token}", params: {"List-Unsubscribe" => "One-Click"}

    assert_response :success
    assert_not @user.wants_notification?(:network, via: :email)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "Slack DM links turn off the Slack channel only" do
    token = NotificationOptOut.token_for(@user, :network, via: :slack)
    get "/unsubscribe/#{token}"
    assert_select "h1", /Turn off network activity Slack DMs/

    post "/unsubscribe/#{token}"
    assert_not @user.wants_notification?(:network, via: :slack)
    assert @user.wants_notification?(:network, via: :email)
  end

  test "bad tokens are not found" do
    get "/unsubscribe/nope"
    assert_response :not_found

    post "/unsubscribe/nope"
    assert_response :not_found
  end
end
