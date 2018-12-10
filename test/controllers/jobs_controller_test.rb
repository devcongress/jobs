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

    assert_enqueued_jobs @company.users.count do
      assert_difference('Job.count') do
        job_params = attributes_for(:job, company_id: @company.id)
        post jobs_url, params: {job: job_params}

        assert_response :created
      end
    end
  end

  test "should fail if company is not client of user" do
    sign_in @user

    job_params = attributes_for(:job, company_id: create(:company).id)

    assert_raise ActionController::RoutingError do
      post jobs_url, params: {job: job_params}
    end
  end

  test "should be able to edit a job post" do
    job = FactoryBot.create(:job, company: @company)
    job_params = attributes_for(:job, company: FactoryBot.create(:company))

    sign_in @user
    put job_url(job), params: {job: job_params}

    job.reload
    assert_redirected_to job
    assert_equal job.company, @company # Job's company cannot be changed.
    assert_equal job.role, job_params[:role]

    updated_attrs = job.attributes.except("id", "created_at", "updated_at", "company_id", "full_text_search")
    updated_attrs.each { |k, v| assert_equal v, job_params[k.to_sym] if v }
  end

  test "should be able to mark a job post (position) as filled" do
    job = FactoryBot.create(:job, company: @company)

    sign_in @user
    post filled_job_url(job)

    job.reload
    assert_redirected_to job
    refute_nil job.filled_at
    assert job.filled_at < DateTime.now
  end

  test "should be able to mark a filled job as vacant" do
    job = FactoryBot.create(:job, company: @company, filled_at: DateTime.now)

    sign_in @user
    post vacant_job_url(job)

    job.reload
    assert_redirected_to job
    assert_nil job.filled_at
  end

  test "search" do
    first = FactoryBot.create(:job, role: "Senior Ruby on Rails Developer")
    second = FactoryBot.create(:job, role: "Senior JavaScript Developer")
    FactoryBot.create(:job) # not found

    get search_jobs_url(q: "senior developer")

    assert_match /2 matches were found/i, @response.body
    assert_match first.role,              @response.body
    assert_match first.requirements,      @response.body
    assert_match second.role,             @response.body
    assert_match second.requirements,     @response.body
  end
end
