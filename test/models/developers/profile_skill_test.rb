require "test_helper"

class Developers::ProfileSkillTest < ActiveSupport::TestCase
  include AccountsTestHelper

  test "adds each skill once per profile" do
    profile = create_profile!
    skill = Skill.create!(name: "Ruby")
    profile.profile_skills.create!(skill:)

    duplicate = profile.profile_skills.build(skill:)
    assert_not duplicate.valid?
  end
end
