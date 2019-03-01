require 'test_helper'

class ProfileControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = FactoryBot.create(:user)
    @company = FactoryBot.create(:company)
    @user.companies << @company
    FactoryBot.create_pair(:job, company: @company)
  end

  test "should require login" do
    get profile_url

    assert_redirected_to new_user_session_url
  end

  test "should show profile of the current user" do
    sign_in @user

    get profile_url

    assert_response :ok

    assert_match new_company_path, @response.body # link to register company
    @user.companies.each do |c|
      # the profile page includes a list of all companies
      # and the number of jobs posted for each.
      assert_match "#{c.name} (#{c.jobs.count})", @response.body
    end
  end

end
