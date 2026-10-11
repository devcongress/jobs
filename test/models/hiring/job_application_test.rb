require "test_helper"

class Hiring::JobApplicationTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup do
    @job = create_job!(company: create_company!)
    @profile = create_profile!
  end

  test "one application per job per profile" do
    @job.job_applications.create!(profile: @profile)
    assert_not @job.job_applications.build(profile: @profile).valid?
  end

  test "only active jobs that accept applications take them" do
    @job.mark_filled!
    assert_not @job.job_applications.build(profile: @profile).valid?

    link_only = create_job!(company: @job.company, accepts_applications: false, apply_url: "https://acme.test/apply")
    assert_not link_only.job_applications.build(profile: @profile).valid?
  end

  test "reaches its company through the job" do
    application = @job.job_applications.create!(profile: @profile)
    assert_equal @job.company, application.company
    assert_equal [application], Hiring::JobApplication.associated_with(@job.company).to_a
  end
end
