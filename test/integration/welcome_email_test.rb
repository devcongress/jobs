require "test_helper"

class WelcomeEmailTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  test "password sign-ups are welcomed once they confirm their email, not before" do
    rodauth = RodauthApp.rodauth(:user)

    rodauth.create_account(login: "new@example.com", password: "password123")
    user = User.find_by!(email: "new@example.com")
    assert user.unverified?
    assert_enqueued_email_with Rodauth::UserMailer, :verify_account, args: ->(args) { args.first(2) == [:user, user.id] }
    assert_not enqueued_jobs.any? { |job| job[:args].second == "welcome" }

    clear_enqueued_jobs
    rodauth.verify_account(account_login: "new@example.com")

    assert user.reload.verified?
    assert_enqueued_email_with Rodauth::UserMailer, :welcome, args: [:user, user.id]
  end
end
