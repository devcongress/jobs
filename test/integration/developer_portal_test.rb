require "test_helper"

class DeveloperPortalTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    @profile = create_profile!(handle: "ada")
    @other = create_profile!(handle: "grace")
    @other.experiences.create!(title: "Admiral", company_name: "US Navy", started_on: Date.new(1943, 1, 1))
    login_user(@profile.user)
  end

  test "shows the owner's own portal" do
    get "/developer/ada"
    assert_response :success
    assert_select "h1", /#{@profile.name}/

    get "/developer/ada/developers_profile"
    assert_response :success

    get "/developer/ada/developers_profile/edit"
    assert_response :success
  end

  test "the dashboard shows who can see the profile" do
    get "/developer/ada"
    assert_select "[data-visibility-banner=members]", /signed-in members only/
    assert_select "[data-visibility-banner] a[href=?]", "/developer/ada/developers_profile/edit#developers_profile_#{@profile.id}_visibility"

    @profile.update!(visibility: :hidden)
    get "/developer/ada"
    assert_select "[data-visibility-banner=hidden]", /Only you can see it/

    @profile.update!(visibility: :everyone)
    get "/developer/ada"
    assert_select "[data-visibility-banner=everyone]", /public/
  end

  test "cannot open someone else's profile portal" do
    get "/developer/grace"
    assert_includes [403, 404], response.status
  end

  test "manages experience within the profile only" do
    post "/developer/ada/developers/experiences", params: {developers_experience: {
      title: "Analyst", company_name: "Analytical Engines", started_on: "1842-01-01"
    }}
    assert_response :redirect

    experience = @profile.experiences.sole
    assert_equal "Analyst", experience.title

    get "/developer/ada/developers/experiences"
    assert_response :success
    assert_includes response.body, "Analytical Engines"
    assert_not_includes response.body, "US Navy"
  end

  test "adds skills from the shared taxonomy" do
    skill = Skill.create!(name: "Ruby")

    post "/developer/ada/developers/profile_skills", params: {developers_profile_skill: {skill: skill.to_signed_global_id.to_s, level: "expert", years: 5}}
    assert_response :redirect

    assert_equal [skill], @profile.skills.to_a
  end
end
