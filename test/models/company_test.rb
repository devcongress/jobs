require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "derives a slug from the name" do
    assert_equal "acme-labs", Company.create!(name: "Acme Labs").slug
  end

  test "uses the slug in URLs" do
    company = Company.create!(name: "Acme Labs")
    assert_equal "acme-labs", company.to_param
  end
end
