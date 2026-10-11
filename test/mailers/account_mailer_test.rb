require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  include AccountsTestHelper

  test "account emails use the branded layout and greet developers by name" do
    user = create_profile!(name: "Ada Lovelace").user

    email = Rodauth::UserMailer.reset_password(:user, user.id, "secret-key")
    assert_equal [user.email], email.to
    assert_equal "Reset your DevCongress Connect password", email.subject
    assert_match "Hi Ada,", email.text_part.body.to_s
    assert_match "/users/reset-password?key=", email.html_part.body.to_s
    assert_match "email-wordmark", email.html_part.body.to_s
  end

  test "login change confirmations go to the new address" do
    user = create_user!

    email = Rodauth::UserMailer.verify_login_change(:user, user.id, "secret-key", "new@example.com")
    assert_equal ["new@example.com"], email.to
    assert_match user.email, email.text_part.body.to_s
    assert_match "/users/verify-login-change?key=", email.text_part.body.to_s
  end

  test "the welcome email sends new users to onboarding" do
    user = create_user!

    email = Rodauth::UserMailer.welcome(:user, user.id)
    assert_equal [user.email], email.to
    assert_equal "Welcome to DevCongress Connect", email.subject
    assert_match "Hi there,", email.text_part.body.to_s
    assert_match %r{https?://example.com(:\d+)?/onboarding}, email.html_part.body.to_s
  end

  test "admin emails say they are about the admin account" do
    admin = Admin.create!(email: "admin@example.com", status: :verified)

    email = Rodauth::AdminMailer.unlock_account(:admin, admin.id, "secret-key")
    assert_equal "Unlock your DevCongress Connect admin account", email.subject
    assert_match "Hi there,", email.text_part.body.to_s
  end
end
