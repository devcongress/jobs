require "test_helper"

class CategorizedEmailTest < ActionMailer::TestCase
  include AccountsTestHelper

  setup do
    @follower = create_profile!(name: "Ama Owusu")
    @followee = create_profile!(name: "Kofi Boateng")
    @follow = Network::Follow.create!(follower: @follower, followee: @followee)
  end

  test "categorised emails carry an unsubscribe link and one-click headers" do
    email = Network::FollowMailer.with(follow: @follow).followed
    token = NotificationOptOut.token_for(@followee.user, :network, via: :email)

    assert_match "/unsubscribe/#{token}", email["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].value
    assert_match "Turn off network activity emails", email.html_part.body.to_s
    assert_match "/unsubscribe/#{token}", email.html_part.body.to_s
    assert_match "/unsubscribe/#{token}", email.text_part.body.to_s
    assert_match "/dashboard/settings/notifications", email.text_part.body.to_s
  end

  test "follow emails respect the network setting" do
    @followee.user.opt_out!(:network, via: :email)
    assert_emails(0) { Network::FollowMailer.with(follow: @follow).followed.deliver_now }
  end

  test "credit emails respect the project credits setting" do
    project = Showcase::Project.create!(owner: @follower, title: "Trotro Times")
    credit = project.contributors.create!(profile: @followee)

    @followee.user.opt_out!(:project_credits, via: :email)
    assert_emails(0) { Showcase::ContributorMailer.with(contributor: credit).invited.deliver_now }

    @follower.user.opt_out!(:project_credits, via: :email)
    assert_emails(0) { Showcase::ContributorMailer.with(contributor: credit).confirmed.deliver_now }
  end

  test "application status emails respect the applications setting" do
    company = create_company!(owner: create_user!)
    job = create_job!(company:, accepts_applications: true)
    application = job.job_applications.create!(profile: @followee)
    application.status = :shortlisted

    @followee.user.opt_out!(:applications, via: :email)
    assert_emails(0) { Hiring::JobApplicationMailer.with(job_application: application, message: nil).status_changed.deliver_now }
  end
end
