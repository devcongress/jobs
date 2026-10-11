require "test_helper"

class OnboardingTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @user = create_user!(email: "grace.hopper@example.com")
  end

  test "users with neither a profile nor a company are sent to onboarding" do
    login_user(@user)
    assert_equal "/onboarding", path

    get "/dashboard"
    assert_redirected_to "/onboarding"
  end

  test "suggests a handle from the email" do
    login_user(@user)
    assert_select "input[name='onboarding[handle]'][value='grace-hopper']"
  end

  test "asks who can see the profile, defaulting to public" do
    login_user(@user)
    assert_select "input[type=radio][name='onboarding[visibility]']", 3
    assert_select "input[type=radio][name='onboarding[visibility]'][value=everyone][checked]"
  end

  test "creates the profile with the chosen visibility" do
    login_user(@user)

    post "/onboarding", params: {onboarding: {developer: "1", first_name: "Grace", handle: "grace", visibility: "members", hiring: "0"}}

    assert_predicate @user.reload.developer_profile, :visible_to_members?
  end

  test "profiles are public when no visibility is given" do
    login_user(@user)

    post "/onboarding", params: {onboarding: {developer: "1", first_name: "Grace", handle: "grace", hiring: "0"}}

    assert_predicate @user.reload.developer_profile, :visible_to_everyone?
  end

  test "creates just a developer profile" do
    login_user(@user)

    assert_difference -> { Developers::Profile.count }, 1 do
      assert_no_difference -> { Company.count } do
        post "/onboarding", params: {onboarding: {developer: "1", first_name: "Grace", other_names: "Hopper", handle: "grace", hiring: "0", company_name: "Ignored"}}
      end
    end

    assert_redirected_to "/developer/grace"
  end

  test "creates just a company" do
    login_user(@user)

    assert_no_difference -> { Developers::Profile.count } do
      post "/onboarding", params: {onboarding: {developer: "0", first_name: "", handle: "", hiring: "1", company_name: "Acme Labs"}}
    end

    company = Company.find_by!(name: "Acme Labs")
    assert_redirected_to "/company/acme-labs"
    assert company.company_users.exists?(user: @user, role: :owner)

    get "/dashboard"
    assert_response :success
    assert_select "a[href=?]", "/setup/developer/new", text: "Developer profile"
  end

  test "creates both" do
    login_user(@user)

    post "/onboarding", params: {onboarding: {developer: "1", first_name: "Grace", other_names: "Hopper", handle: "grace", hiring: "1", company_name: "Acme Labs"}}

    assert_redirected_to "/dashboard/"
    assert @user.reload.developer_profile.present?
    assert @user.companies.exists?(name: "Acme Labs")
  end

  test "requires at least one" do
    login_user(@user)

    post "/onboarding", params: {onboarding: {developer: "0", hiring: "0"}}

    assert_response :unprocessable_entity
    assert_includes response.body, "Choose a developer profile, a company, or both"
  end

  test "creates nothing when either record is invalid" do
    create_profile!(handle: "grace")
    login_user(@user)

    assert_no_difference ["Developers::Profile.count", "Company.count"] do
      post "/onboarding", params: {onboarding: {developer: "1", first_name: "Grace", other_names: "Hopper", handle: "grace", hiring: "1", company_name: ""}}
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Handle has already been taken"
    assert_includes response.body, "Company name can&#39;t be blank"
  end

  test "onboarded users are sent back to the dashboard" do
    create_profile!(user: @user)
    login_user(@user)

    get "/onboarding"
    assert_redirected_to "/dashboard/"
  end

  test "users can set up a company later" do
    create_profile!(user: @user)
    login_user(@user)

    post "/setup/company", params: {company: {name: "Later Co"}}
    assert_redirected_to "/company/later-co"
    assert @user.companies.exists?(name: "Later Co")
  end

  test "company-only users can create a developer profile later" do
    create_company!(owner: @user)
    login_user(@user)

    get "/setup/developer/new"
    assert_response :success
    assert_select "input[type=radio][name='developers_profile[visibility]'][value=everyone][checked]"

    post "/setup/developer", params: {developers_profile: {first_name: "Grace", other_names: "Hopper", handle: "grace", visibility: "hidden"}}
    assert_redirected_to "/developer/grace"
    assert_predicate @user.reload.developer_profile, :visible_to_hidden?

    get "/setup/developer/new"
    assert_redirected_to "/developer/grace"
  end

  test "guests cannot onboard" do
    get "/onboarding"
    assert_redirected_to "/users/login"
  end
end
