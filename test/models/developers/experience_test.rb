require "test_helper"

class Developers::ExperienceTest < ActiveSupport::TestCase
  include AccountsTestHelper

  test "cannot end before it starts" do
    experience = create_profile!.experiences.build(title: "Dev", company_name: "Acme", started_on: Date.new(2020, 1, 1), ended_on: Date.new(2019, 1, 1))

    assert_not experience.valid?
    assert experience.errors[:ended_on].any?
  end

  test "links only profile skills belonging to the same profile" do
    profile = create_profile!
    experience = profile.experiences.create!(title: "Developer", company_name: "Acme", started_on: Date.new(2020, 1, 1))
    own_profile_skill = profile.profile_skills.create!(skill: Skill.create!(name: "Ruby"))
    other_profile_skill = create_profile!.profile_skills.create!(skill: Skill.create!(name: "Elixir"))

    experience.profile_skills << own_profile_skill
    assert_equal [own_profile_skill], experience.profile_skills.reload

    link = experience.experience_skills.new(profile_skill: other_profile_skill)
    assert_not link.valid?
    assert_includes link.errors[:profile_skill], "must belong to the same profile as the experience"
  end

  test "removing an experience or profile skill removes its links" do
    profile = create_profile!
    first_experience = profile.experiences.create!(title: "Developer", company_name: "Acme", started_on: Date.new(2020, 1, 1))
    second_experience = profile.experiences.create!(title: "Lead", company_name: "Beta", started_on: Date.new(2022, 1, 1))
    first_profile_skill = profile.profile_skills.create!(skill: Skill.create!(name: "Ruby"))
    second_profile_skill = profile.profile_skills.create!(skill: Skill.create!(name: "Rails"))
    first_link = first_experience.experience_skills.create!(profile_skill: first_profile_skill)
    second_link = second_experience.experience_skills.create!(profile_skill: second_profile_skill)

    first_experience.destroy!
    assert_not Developers::ExperienceSkill.exists?(first_link.id)

    second_profile_skill.destroy!
    assert_not Developers::ExperienceSkill.exists?(second_link.id)
  end
end
