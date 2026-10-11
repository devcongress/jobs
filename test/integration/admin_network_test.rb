require "test_helper"

class AdminNetworkTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  test "admins can review projects, credits, follows and endorsements" do
    ada = create_profile!(name: "Ada Lovelace", handle: "ada")
    kwame = create_profile!(name: "Kwame Mensah", handle: "kwame")
    ada.outgoing_follows.create!(followee: kwame)
    kwame.outgoing_follows.create!(followee: ada)
    ruby = kwame.profile_skills.create!(skill: Skill.create!(name: "Ruby"))
    endorsement = ruby.endorsements.create!(endorser: ada)
    project = Showcase::Project.create!(owner: ada, title: "Harbour")
    credit = project.contributors.create!(profile: kwame)

    admin = Admin.create!(email: "admin@example.com", status: :verified, password_hash: BCrypt::Password.create("password123"))
    login_as(admin, portal: :admin)

    %w[/admin/showcase/projects /admin/showcase/project_contributors /admin/network/follows /admin/network/endorsements].each do |path|
      get path
      assert_response :success, path
    end
    get "/admin/showcase/projects/#{project.id}"
    assert_includes response.body, "Harbour"
    get "/admin/showcase/project_contributors/#{credit.id}"
    assert_includes response.body, "Kwame Mensah"

    # Admins can hide a project and remove an endorsement.
    patch "/admin/showcase/projects/#{project.id}", params: {showcase_project: {visibility: "hidden"}}
    assert project.reload.visible_to_hidden?
    delete "/admin/network/endorsements/#{endorsement.id}"
    assert_equal 0, ruby.reload.endorsements_count
  end
end
