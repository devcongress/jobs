require "test_helper"

class CompanyTeamTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @owner = create_user!
    @company = create_company!(owner: @owner, name: "Acme Hiring")
    @recruiter = create_user!
    @company.company_users.create!(user: @recruiter, role: :recruiter)
  end

  test "the dashboard's Invite button opens the invite form for owners" do
    login_user(@owner)
    invite_url = "/company/#{@company.slug}/company/record_actions/invite_user"

    get "/company/#{@company.slug}"
    assert_response :success
    assert_select "a[href=?]", invite_url

    get invite_url
    assert_response :success
  end

  test "recruiters don't get an Invite button" do
    login_user(@recruiter)

    get "/company/#{@company.slug}"
    assert_response :success
    assert_select "a[href$=?]", "/record_actions/invite_user", count: 0
  end
end
