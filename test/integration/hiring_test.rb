require "test_helper"

class HiringTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @recruiter = create_user!
    @company = create_company!(owner: @recruiter, name: "Acme Labs")
    @other_company = create_company!(name: "Other Co")
    @developer = create_profile!(handle: "ada")
  end

  test "companies post, publish and manage their jobs" do
    login_user(@recruiter)

    post "/company/acme-labs/hiring/job_posts", params: {hiring_job_post: {
      title: "Rails Engineer", description: "Ship features.", employment_type: "full_time", accepts_applications: "1"
    }}
    job = @company.job_posts.find_by!(title: "Rails Engineer")
    assert_equal :draft, job.status

    # A new company's first job goes to review instead of going live.
    post "/company/acme-labs/hiring/job_posts/#{job.id}/record_actions/publish"
    assert_equal :pending_review, job.reload.status
    follow_redirect!
    assert_includes response.body, "Submitted for review"

    get "/jobs"
    assert_not_includes response.body, "Rails Engineer"

    job.approve!
    assert_equal :active, job.reload.status
    get "/jobs"
    assert_includes response.body, "Rails Engineer"

    # Trusted now, so the next job publishes straight away.
    post "/company/acme-labs/hiring/job_posts", params: {hiring_job_post: {
      title: "Second Role", description: "More features.", employment_type: "contract", accepts_applications: "1"
    }}
    second = @company.job_posts.find_by!(title: "Second Role")
    post "/company/acme-labs/hiring/job_posts/#{second.id}/record_actions/publish"
    assert_equal :active, second.reload.status

    post "/company/acme-labs/hiring/job_posts/#{job.id}/record_actions/mark_filled"
    assert_equal :filled, job.reload.status

    get "/company/acme-labs"
    assert_response :success
    assert_includes response.body, "Rails Engineer"

    get "/company/acme-labs/hiring/job_posts/#{job.id}"
    assert_response :success
  end

  test "companies only see their own jobs and applicants" do
    other_job = create_job!(company: @other_company, title: "Secret Role")
    other_job.job_applications.create!(profile: create_profile!(name: "Someone Else"))
    login_user(@recruiter)

    get "/company/acme-labs/hiring/job_posts"
    assert_not_includes response.body, "Secret Role"

    get "/company/acme-labs/hiring/job_applications"
    assert_not_includes response.body, "Someone Else"

    get "/company/acme-labs/hiring/job_posts/#{other_job.id}"
    assert_includes [403, 404], response.status
  end

  test "developers browse active jobs and apply once" do
    job = create_job!(company: @company, title: "Rails Engineer")
    create_job!(company: @company, title: "Draft Role", published: false)
    login_user(@developer.user)

    get "/developer/ada/hiring/job_posts"
    assert_response :success
    assert_includes response.body, "Rails Engineer"
    assert_not_includes response.body, "Draft Role"

    get "/developer/ada/hiring/job_posts/#{job.id}"
    assert_response :success
    assert_includes response.body, "Rails Engineer at Acme Labs"

    post "/developer/ada/hiring/job_posts/#{job.id}/record_actions/apply", params: {interaction: {cover_note: "Hi!"}}
    application = @developer.job_applications.sole
    assert_equal job, application.job_post
    assert application.submitted?
    assert_equal "Hi!", application.cover_note

    post "/developer/ada/hiring/job_posts/#{job.id}/record_actions/apply"
    assert_equal 1, @developer.job_applications.count

    get "/developer/ada/hiring/job_applications"
    assert_includes response.body, "Rails Engineer"
  end

  test "developers cannot change jobs or see other applicants" do
    job = create_job!(company: @company)
    rival = create_profile!(name: "Rival Applicant")
    job.job_applications.create!(profile: rival)
    login_user(@developer.user)

    post "/developer/ada/hiring/job_posts/#{job.id}/record_actions/mark_filled"
    assert job.reload.active?

    get "/developer/ada/hiring/job_applications"
    assert_not_includes response.body, "Rival Applicant"
  end

  test "companies move applicants through their pipeline and developers can withdraw" do
    job = create_job!(company: @company)
    application = job.job_applications.create!(profile: @developer)

    login_user(@recruiter)
    post "/company/acme-labs/hiring/job_applications/#{application.id}/record_actions/update_status",
      params: {interaction: {status: "shortlisted"}}
    assert application.reload.shortlisted?

    sign_out(portal: :user)
    login_user(@developer.user)
    post "/developer/ada/hiring/job_applications/#{application.id}/record_actions/withdraw"
    assert application.reload.withdrawn?
  end
end
