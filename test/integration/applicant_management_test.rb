require "test_helper"

class ApplicantManagementTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @recruiter = create_user!
    @company = create_company!(owner: @recruiter, name: "Acme Labs")
    @job = create_job!(company: @company, title: "Rails Engineer", accepts_applications: true)
    @applicant = create_profile!(name: "Kwame Mensah", handle: "kwame")
    @application = @job.job_applications.create!(profile: @applicant, cover_note: "Keen to help!")
    @base = "/company/acme-labs/hiring/job_applications"
  end

  test "the hiring team gets a board, a table and a rich application page" do
    login_user(@recruiter)

    get @base
    assert_response :success
    %w[New Reviewing Shortlisted Hired Rejected Withdrawn].each { |stage| assert_includes response.body, stage }

    get "#{@base}?view=table&q[search]=kwame"
    assert_response :success
    assert_includes response.body, "Kwame Mensah"
    # The table uses the board's stage names.
    assert_select "td span", text: "New"
    assert_select "td span", text: "Submitted", count: 0

    get "#{@base}?view=table&q[search]=nobody-matches"
    assert_not_includes response.body, "Kwame Mensah"

    get "#{@base}/#{@application.id}"
    assert_response :success
    assert_includes response.body, "Application from Kwame Mensah"
    assert_includes response.body, "Keen to help!"
    assert_includes response.body, @applicant.user.email
  end

  test "notes, ratings and stage changes build an activity log" do
    login_user(@recruiter)

    post "#{@base}/#{@application.id}/record_actions/add_note", params: {interaction: {body: "Strong take-home."}}
    note = @application.notes.note.last
    assert_equal "Strong take-home.", note.body
    assert_equal @recruiter, note.author

    post "#{@base}/#{@application.id}/record_actions/rate", params: {interaction: {rating: "4"}}
    assert_equal 4, @application.reload.rating

    assert_enqueued_email_with Hiring::JobApplicationMailer, :status_changed,
      params: {job_application: @application, message: "Let's talk Tuesday."} do
      post "#{@base}/#{@application.id}/record_actions/update_status",
        params: {interaction: {status: "shortlisted", message: "Let's talk Tuesday."}}
    end
    assert @application.reload.shortlisted?
    change = @application.notes.status_change.last
    assert_equal %w[submitted shortlisted], [change.from_status, change.to_status]
    assert_equal @recruiter, change.author

    get "#{@base}/#{@application.id}"
    assert_includes response.body, "Strong take-home."
    assert_includes response.body, "Let&#39;s talk Tuesday."
  end

  test "rejecting sends the applicant an optional personal message" do
    login_user(@recruiter)

    post "#{@base}/#{@application.id}/record_actions/reject", params: {interaction: {message: "We went with someone more senior."}}
    assert @application.reload.rejected?

    email = Hiring::JobApplicationMailer.with(job_application: @application, message: "We went with someone more senior.").status_changed
    assert_match "We went with someone more senior.", email.text_part.body.to_s
    assert_match "A note from Acme Labs", email.html_part.body.to_s
  end

  test "dragging a card on the board moves the applicant" do
    login_user(@recruiter)

    post "#{@base}/#{@application.id}/kanban_move", params: {from_column: "submitted", to_column: "reviewing", to_index: 0},
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert @application.reload.reviewing?
    assert_equal @recruiter, @application.notes.status_change.last.author

    # Withdrawn applicants can't be moved.
    @application.update!(status: :withdrawn)
    post "#{@base}/#{@application.id}/kanban_move", params: {from_column: "withdrawn", to_column: "reviewing", to_index: 0},
      headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert @application.reload.withdrawn?
  end

  test "bulk move rejects several applicants at once" do
    second = @job.job_applications.create!(profile: create_profile!(name: "Efua Asante"))
    login_user(@recruiter)

    post "#{@base}/bulk_actions/bulk_move", params: {ids: [@application.id, second.id], interaction: {status: "rejected"}}
    assert @application.reload.rejected?
    assert second.reload.rejected?
  end

  test "CSV export lists the company's applicants with contact details" do
    login_user(@recruiter)

    get "#{@base}/export_csv"
    assert_response :success
    assert_includes response.body, "Kwame Mensah"
    assert_includes response.body, @applicant.user.email
    assert_includes response.body, "Rails Engineer"
  end

  test "other companies and the applicant can't use the hiring tools" do
    outsider = create_user!
    create_company!(owner: outsider, name: "Other Co")
    login_user(outsider)
    get "/company/other-co/hiring/job_applications/#{@application.id}"
    assert_response :not_found

    reset!
    login_user(@applicant.user)
    get "/developer/kwame/hiring/job_applications/#{@application.id}"
    assert_response :success
    assert_not_includes response.body, "Add note"

    post "/developer/kwame/hiring/job_applications/#{@application.id}/record_actions/add_note", params: {interaction: {body: "sneaky"}}
    assert_empty @application.notes.note
  end
end
