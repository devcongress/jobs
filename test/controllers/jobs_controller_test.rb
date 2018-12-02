require 'test_helper'

class JobsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ERB::Util

  setup do
    @available_jobs = create_list(:job, 3, created_at: 1.day.ago)
    @archived_job = create(:job, archived: true) # one archived job
    @user = create(:user)
    @company = create(:company)
    @user.companies << @company
  end

  test "should get index" do
    get jobs_url

    assert_response :success

    @available_jobs.each do |job|
      job_title = "#{job.role} at #{job.company.name}"
      assert_match html_escape(job_title), @response.body
    end

    # archived jobs are not displayed
    archived_job_title = "#{@archived_job.role} at #{@archived_job.company.name}"
    refute_match archived_job_title, @response.body
  end

  test "should show a job" do
    job = @available_jobs.first

    get job_url(job)

    assert_response :success
    assert_match job.role,          @response.body
    assert_match job.qualification, @response.body
    assert_match job.salary,        @response.body
    assert_match job.duration,      @response.body
    assert_match html_escape(job.company.name),  @response.body
  end

  test "should not find archived job" do
    assert_raise ActionController::RoutingError do
      get job_url(@archived_job)
    end
  end

  test "should fail for unauthenticated user" do
    job_params = attributes_for(:job)
    post jobs_url, params: {job: job_params}
    assert_redirected_to new_user_session_url
  end

  test "should create a new job post for user's client" do
    sign_in @user

    assert_difference('Job.count') do
      job_params = attributes_for(:job, company_id: @company.id)
      post jobs_url, params: {job: job_params}

      assert_response :created
    end
  end

  test "should fail if company is not client of user" do
    sign_in @user

    job_params = attributes_for(:job, company_id: create(:company).id)

    assert_raise ActionController::RoutingError do
      post jobs_url, params: {job: job_params}
    end
  end
end
