require "application_system_test_case"

class CompaniesTest < ApplicationSystemTestCase
  setup do
    @user = FactoryBot.create(:user)
    sign_in @user
  end

  test "creating a company" do
    industry = FactoryBot.create(:industry)
    company = FactoryBot.build(:company, industry: industry.name)

    visit new_company_url

    fill_in "Name",           with: company.name
    select  company.industry, from: "Industry"
    fill_in "About",          with: company.description
    fill_in "Website",        with: company.website
    fill_in "Contact Email",  with: company.email
    fill_in "Contact Phone",  with: company.phone
    fill_in "City",           with: company.city
    fill_in "State/Region",   with: company.state_or_region
    fill_in "Post/Zip Code",  with: company.post_code
    fill_in "Country",        with: company.country

    click_on "Register"

    assert_text company.name
    assert_text company.industry
    assert_text company.website
    assert_text company.description
    assert_text company.city
    assert_text company.country
  end
end
