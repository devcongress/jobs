require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  test "renders the landing page" do
    get root_path
    assert_response :success
    assert_select "h1", /Africa.s builders/
  end

  test "new profiles the viewer can't see show as anonymous placeholders" do
    create_profile!(name: "Pat Public", handle: "pat", visibility: :everyone)
    create_profile!(name: "Mo Members", handle: "momo", visibility: :members)
    create_profile!(name: "Hal Hidden", handle: "hal", visibility: :hidden)

    get root_path
    assert_includes response.body, "Pat Public"
    assert_not_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"
    assert_equal 2, response.body.scan("A new builder joined").size
    assert_includes response.body, "Members-only profile."

    login_user(create_user!)
    get root_path
    assert_includes response.body, "Mo Members"
    assert_not_includes response.body, "Hal Hidden"
    assert_includes response.body, "Their profile is private."
    assert_not_includes response.body, "Members-only profile."
  end
end
