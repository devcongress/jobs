require "test_helper"

class Hiring::JobReviewTest < ActiveSupport::TestCase
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @owner = create_user!
    @company = create_company!(owner: @owner, name: "Newco")
    @admin = Admin.create!(email: "admin@example.com", status: :verified)
  end

  test "a new company's first job waits for review and admins are emailed" do
    job = create_job!(company: @company, published: false)

    assert_enqueued_email_with Hiring::JobReviewMailer, :review_requested, params: {job_post: job} do
      job.publish!
    end

    assert job.pending_review?
    assert_not job.active?
    assert_not Hiring::JobPost.active.include?(job)
    assert_includes Hiring::JobPost.pending_review, job
  end

  test "approval makes the job live, trusts the company and emails it" do
    job = create_job!(company: @company, review: true)

    assert_enqueued_email_with Hiring::JobReviewMailer, :approved, params: {job_post: job, recipient: @owner} do
      job.approve!
    end

    assert job.active?
    assert @company.reload.jobs_trusted?
    assert_in_delta Hiring::JobPost::VALIDITY_PERIOD.from_now, job.expires_at, 5

    second = create_job!(company: @company, title: "Second", published: false)
    assert_no_enqueued_emails { second.publish! }
    assert second.active?
  end

  test "declining sends the job back to draft with a note" do
    job = create_job!(company: @company, review: true)

    assert_enqueued_email_with Hiring::JobReviewMailer, :declined, params: {job_post: job, recipient: @owner, reason: "Add a salary range"} do
      job.decline!("Add a salary range")
    end

    assert_equal :draft, job.status
    assert_not @company.reload.jobs_trusted?
  end

  test "review emails go to the right people" do
    job = create_job!(company: @company, title: "Rails Engineer", review: true)

    email = Hiring::JobReviewMailer.with(job_post: job).review_requested
    assert_equal ["admin@example.com"], email.to
    assert_match "Newco", email.subject
    assert_match "/admin/hiring/job_posts/#{job.to_param}", email.text_part.body.to_s

    job.approve!
    @owner.opt_out!(:applications, via: :email)
    email = Hiring::JobReviewMailer.with(job_post: job, recipient: @owner).approved
    assert_equal [@owner.email], email.to
    assert_match "/jobs/#{job.to_param}", email.text_part.body.to_s
    assert_nil email["List-Unsubscribe"]

    email = Hiring::JobReviewMailer.with(job_post: job, recipient: @owner, reason: "Needs a salary").declined
    assert_equal [@owner.email], email.to
    assert_match "Needs a salary", email.text_part.body.to_s
  end
end
