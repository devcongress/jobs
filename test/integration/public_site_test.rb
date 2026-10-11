require "test_helper"

class PublicSiteTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @public = create_profile!(name: "Pat Public", handle: "pat", visibility: :everyone, contact_email: "pat@example.com",
      contact_visibility: :members, availability: :looking, remote_ok: true, country: "Ghana")
    @members = create_profile!(name: "Mo Members", handle: "momo", visibility: :members, contact_email: "mo@example.com",
      contact_visibility: :everyone, country: "Nigeria")
    @hidden = create_profile!(name: "Hal Hidden", handle: "hal", visibility: :hidden)
    @public.profile_skills.create!(skill: Skill.create!(name: "Elixir"))

    @company = create_company!(name: "Acme Labs")
    @public_job = create_job!(company: @company, title: "Public Role", apply_url: "https://acme.test/apply")
    @members_job = create_job!(company: @company, title: "Members Role", visibility: :members)
    create_job!(company: @company, title: "Draft Role", published: false)
    create_job!(company: @company, title: "Filled Role").mark_filled!
  end

  test "guests see only public profiles" do
    get "/devs"
    assert_response :success
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"

    get "/@pat"
    assert_response :success
    get "/@momo"
    assert_response :not_found
    get "/@hal"
    assert_response :not_found
  end

  test "members also see members-only profiles, never hidden ones" do
    login_user(create_user!)

    get "/devs"
    assert_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"

    get "/@momo"
    assert_response :success
    get "/@hal"
    assert_response :not_found
  end

  test "owners can always see their own profile" do
    login_user(@hidden.user)

    get "/@hal"
    assert_response :success
    assert_includes response.body, "only you can see it"
  end

  test "contact details follow the contact visibility setting" do
    get "/@pat"
    assert_not_includes response.body, "pat@example.com"
    assert_includes response.body, "to see contact details"

    login_user(create_user!)
    get "/@pat"
    assert_includes response.body, "pat@example.com"
    get "/@momo"
    assert_includes response.body, "mo@example.com"
  end

  test "directory search and filters" do
    get "/devs", params: {q: "elixir"}
    assert_includes response.body, "Pat Public"

    login_user(create_user!)
    get "/devs", params: {country: "Nigeria"}
    assert_includes response.body, "Mo Members"
    assert_not_includes response.body, "Pat Public"

    get "/devs", params: {availability: "looking", remote: "1"}
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"

    get "/devs", params: {skill: "elixir"}
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
  end

  test "user-written markdown can't inject markup" do
    @public.update!(bio: "Hello <script>alert(1)</script> **world**")
    get "/@pat"
    assert_includes response.body, "<strong>world</strong>"
    assert_not_includes response.body, "<script>alert(1)</script>"
  end

  test "guests see only public, active jobs" do
    get "/jobs"
    assert_response :success
    assert_includes response.body, "Public Role"
    %w[Members\ Role Draft\ Role Filled\ Role].each { |title| assert_not_includes response.body, title }

    get "/jobs/#{@public_job.to_param}"
    assert_response :success
    assert_includes response.body, "Log in to apply"
    assert_includes response.body, "https://acme.test/apply"

    get "/jobs/#{@members_job.to_param}"
    assert_response :not_found
  end

  test "members see members-only jobs and the right way to apply" do
    user = create_user!
    login_user(user)

    get "/jobs"
    assert_includes response.body, "Members Role"

    get "/jobs/#{@members_job.to_param}"
    assert_response :success
    assert_includes response.body, "Create a developer profile to apply"

    profile = create_profile!(user:, handle: "applicant")
    get "/jobs/#{@public_job.to_param}"
    assert_select "a[href='/developer/applicant/hiring/job_posts/#{@public_job.to_param}/record_actions/apply']", "Apply with your profile"

    @public_job.job_applications.create!(profile:)
    get "/jobs/#{@public_job.to_param}"
    assert_includes response.body, "View your application"
  end

  test "company pages list only the jobs the viewer can see" do
    get "/companies/acme-labs"
    assert_response :success
    assert_includes response.body, "Public Role"
    assert_not_includes response.body, "Members Role"

    get "/companies/nope"
    assert_response :not_found
  end

  test "the landing page only shows what the viewer can see" do
    get "/"
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
    assert_includes response.body, "Public Role"
    assert_not_includes response.body, "Members Role"
    assert_select "a[href='/@pat']"
  end
end
