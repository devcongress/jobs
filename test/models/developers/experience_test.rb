require "test_helper"

class Developers::ExperienceTest < ActiveSupport::TestCase
  include AccountsTestHelper

  test "cannot end before it starts" do
    experience = create_profile!.experiences.build(title: "Dev", company_name: "Acme", started_on: Date.new(2020, 1, 1), ended_on: Date.new(2019, 1, 1))

    assert_not experience.valid?
    assert experience.errors[:ended_on].any?
  end
end
