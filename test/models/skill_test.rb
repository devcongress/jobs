require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "derives a slug and rejects duplicate names" do
    assert_equal "ruby-on-rails", Skill.create!(name: " Ruby  on Rails ").slug
    assert_not Skill.new(name: "ruby on rails").valid?
  end
end
