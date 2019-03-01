require 'test_helper'

class CompaniesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ERB::Util

  setup do
    @company = FactoryBot.create(:company)
    @user = FactoryBot.create(:user)
    @user.companies << @company
    FactoryBot.create_pair(:job, company: @company)
  end

  test "guest users should not be able to register a company" do
    company_params = attributes_for(:company)

    post companies_url, params: {company: company_params}
    assert_redirected_to new_user_session_url

    company = Company.find_by(name: company_params[:name])
    assert company.nil?
  end

  test "should create a new company" do
    company_params = attributes_for(:company)

    sign_in @user
    post companies_url, params: {company: company_params}
    
    company = Company.find_by(name: company_params[:name])

    assert_redirected_to company
    assert company.website     == company_params[:website]
    assert company.description == company_params[:description]

    assert @user.companies.find_by(id: company.id)
  end

  test "should show existing company" do
    get company_url(@company)

    assert_response :ok
    assert_match html_escape(@company.name),     @response.body
    assert_match html_escape(@company.industry), @response.body
    assert_match @company.website,               @response.body
    assert_match @company.description,           @response.body

    # edit link should not be visible
    refute_match edit_company_path(@company), @response.body

    # it shows all jobs of the company
    @company.jobs.each do |job|
      assert_match job.role, @response.body
    end
  end

  test "should show edit link for company owner" do
    sign_in @user

    get company_url(@company)

    assert_response :ok
    assert_match html_escape(@company.name),     @response.body
    assert_match html_escape(@company.industry), @response.body
    assert_match @company.website,               @response.body
    assert_match @company.description,           @response.body

    # edit link should be visible
    assert_match edit_company_path(@company), @response.body
  end
end
