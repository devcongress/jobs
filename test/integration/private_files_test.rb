require "test_helper"

class PrivateFilesTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @company = create_company!(owner: create_user!, name: "Acme Labs")
    @job = create_job!(company: @company, accepts_applications: true)
    @profile = create_profile!(handle: "kwame")
  end

  test "applicants can attach a CV, which is stored privately" do
    login_user(@profile.user)

    post "/developer/kwame/hiring/job_posts/#{@job.id}/record_actions/apply",
      params: {interaction: {cover_note: "Hi", resume: fixture_file_upload("cv.pdf", "application/pdf")}}
    application = @profile.job_applications.sole
    assert application.resume.attached?
    assert_equal "application/pdf", application.resume.content_type
    assert_not application.resume.url.to_s.start_with?(Rails.public_path.to_s), "uploads must not live under public/"
  end

  test "only real CVs are accepted" do
    login_user(@profile.user)

    post "/developer/kwame/hiring/job_posts/#{@job.id}/record_actions/apply",
      params: {interaction: {resume: fixture_file_upload("not-a-cv.html", "text/html")}}
    assert_empty @profile.job_applications
  end

  test "files are only served through signed, expiring links" do
    application = @job.job_applications.new(profile: @profile)
    application.resume = Rack::Test::UploadedFile.new(file_fixture("cv.pdf"), "application/pdf")
    application.save!
    attachment = application.resume.attachment

    get "/files/#{PrivateFilesHelper.token_for(attachment)}"
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert response.body.start_with?("%PDF")

    get "/files/not-a-valid-token"
    assert_response :not_found

    token = PrivateFilesHelper.token_for(attachment, expires_in: 1.minute)
    travel 2.minutes do
      get "/files/#{token}"
      assert_response :not_found
    end
  end
end
