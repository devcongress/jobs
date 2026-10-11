require "test_helper"

class ShowcaseTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @ada = create_profile!(name: "Ada Lovelace", handle: "ada", visibility: :everyone)
    @kwame = create_profile!(name: "Kwame Mensah", handle: "kwame", visibility: :everyone)
    @ruby = Skill.create!(name: "Ruby")
  end

  test "an owner adds a project and credits a contributor, who confirms" do
    login_user(@ada.user)

    post "/developer/ada/showcase/projects", params: {showcase_project: {
      title: "Momo Pay SDK", summary: "Mobile money payments.", body: "## Why\n\nBecause.",
      skills: [@ruby.to_signed_global_id.to_s], repo_url: "https://github.com/example/momo", visibility: "everyone"
    }}
    project = Showcase::Project.find_by!(title: "Momo Pay SDK")
    assert_equal @ada, project.owner
    assert_equal "momo-pay-sdk", project.slug

    assert_enqueued_email_with Showcase::ContributorMailer, :invited, params: ->(params) { params[:contributor].profile == @kwame } do
      post "/developer/ada/showcase/projects/#{project.id}/nested_contributors",
        params: {showcase_project_contributor: {handle: "@kwame", role: "Payments API"}}
    end
    credit = project.contributors.find_by!(profile: @kwame)
    assert credit.pending?

    # Unconfirmed credits stay off public pages.
    get "/projects/momo-pay-sdk"
    assert_response :success
    assert_includes response.body, "Momo Pay SDK"
    assert_not_includes response.body, "Kwame Mensah"
    get "/@kwame"
    assert_not_includes response.body, "Momo Pay SDK"

    # Kwame confirms from the Credits page.
    reset!
    login_user(@kwame.user)
    get "/developer/kwame/showcase/project_contributors"
    assert_includes response.body, "Momo Pay SDK"
    assert_enqueued_email_with Showcase::ContributorMailer, :confirmed, params: {contributor: credit} do
      post "/developer/kwame/showcase/project_contributors/#{credit.id}/record_actions/confirm"
    end
    assert credit.reload.confirmed?

    get "/projects/momo-pay-sdk"
    assert_includes response.body, "Kwame Mensah"
    assert_includes response.body, "Payments API"
    get "/@kwame"
    assert_includes response.body, "Momo Pay SDK"
    get "/projects?skill=ruby"
    assert_includes response.body, "Momo Pay SDK"
  end

  test "a contributor can decline a credit, and can't edit the owner's project" do
    project = Showcase::Project.create!(owner: @ada, title: "Trotro Times")
    credit = project.contributors.create!(profile: @kwame)

    login_user(@kwame.user)
    get "/developer/kwame/showcase/projects/#{project.id}"
    assert_response :not_found
    patch "/developer/kwame/showcase/project_contributors/#{credit.id}", params: {showcase_project_contributor: {role: "Owner"}}
    assert_nil credit.reload.role

    post "/developer/kwame/showcase/project_contributors/#{credit.id}/record_actions/decline"
    assert_redirected_to "/developer/kwame/showcase/project_contributors"
    assert_not Showcase::ProjectContributor.exists?(credit.id)
  end

  test "owners can't add themselves, unknown or hidden developers" do
    hidden = create_profile!(handle: "secret", visibility: :hidden)
    project = Showcase::Project.create!(owner: @ada, title: "Harbour")

    assert_not project.contributors.new(handle: "ada").valid?
    assert_not project.contributors.new(handle: "nobody").valid?
    assert_not project.contributors.new(handle: hidden.handle).valid?
    assert project.contributors.new(handle: "@Kwame").valid?
  end

  test "developers only see their own projects and credits in the portal" do
    other = Showcase::Project.create!(owner: @kwame, title: "Kwame's thing")
    mine = Showcase::Project.create!(owner: @ada, title: "Ada's thing")
    unrelated = Showcase::Project.create!(owner: @kwame, title: "Unrelated").contributors.create!(profile: create_profile!)

    login_user(@ada.user)
    get "/developer/ada/showcase/projects"
    assert_includes response.body, "Ada&#39;s thing"
    assert_not_includes response.body, "Kwame&#39;s thing"

    get "/developer/ada/showcase/projects/#{other.id}/nested_contributors"
    assert_response :not_found

    get "/developer/ada/showcase/project_contributors/#{unrelated.id}"
    assert_response :not_found

    # Credits can only be added under one of your own projects.
    post "/developer/ada/showcase/project_contributors", params: {showcase_project_contributor: {handle: "kwame"}}
    assert_includes [403, 404], response.status
    assert_equal 1, Showcase::ProjectContributor.count
    assert mine
  end

  test "project visibility follows the project and its owner's profile" do
    project = Showcase::Project.create!(owner: @ada, title: "Members thing", visibility: :members)
    get "/projects/#{project.slug}"
    assert_response :not_found

    @ada.update!(visibility: :hidden)
    project.update!(visibility: :everyone)
    get "/projects/#{project.slug}"
    assert_response :not_found
    get "/projects"
    assert_not_includes response.body, "Members thing"

    login_user(@ada.user)
    get "/projects/#{project.slug}"
    assert_response :success
    assert_includes response.body, "This is your project"
  end

  test "contributors with hidden profiles don't show on public pages" do
    secret = create_profile!(name: "Secret Squirrel", handle: "secret", visibility: :hidden)
    project = Showcase::Project.create!(owner: @ada, title: "Harbour")
    project.contributors.create!(profile: secret, status: :confirmed)

    get "/projects/harbour"
    assert_not_includes response.body, "Secret Squirrel"
    get "/projects"
    assert_includes response.body, "Harbour"
    assert_not_includes response.body, "Secret Squirrel"
    get "/@ada"
    assert_not_includes response.body, "Secret Squirrel"
  end

  test "slugs stay unique and fixed" do
    first = Showcase::Project.create!(owner: @ada, title: "Harbour")
    second = Showcase::Project.create!(owner: @kwame, title: "Harbour")
    assert_equal %w[harbour harbour-2], [first.slug, second.slug]
    first.update!(title: "Harbour v2")
    assert_equal "harbour", first.reload.slug
  end
end
