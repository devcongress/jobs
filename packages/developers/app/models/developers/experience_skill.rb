# == Schema Information
#
# Table name: developers_experience_skills
#
#  id               :integer          not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  experience_id    :integer          not null
#  profile_skill_id :integer          not null
#
# Indexes
#
#  idx_on_experience_id_profile_skill_id_491a95c723        (experience_id,profile_skill_id) UNIQUE
#  index_developers_experience_skills_on_profile_skill_id  (profile_skill_id)
#
# Foreign Keys
#
#  experience_id     (experience_id => developers_experiences.id) ON DELETE => cascade
#  profile_skill_id  (profile_skill_id => developers_profile_skills.id) ON DELETE => cascade
#
require_relative "../developers"

class Developers::ExperienceSkill < Developers::ResourceRecord
  belongs_to :experience, class_name: "Developers::Experience", inverse_of: :experience_skills
  belongs_to :profile_skill, class_name: "Developers::ProfileSkill", inverse_of: :experience_skills

  validates :profile_skill, uniqueness: {scope: :experience_id}
  validate :profile_skill_belongs_to_experience_profile

  private

  def profile_skill_belongs_to_experience_profile
    return if experience.nil? || profile_skill.nil?
    return if experience.profile_id == profile_skill.profile_id

    errors.add(:profile_skill, "must belong to the same profile as the experience")
  end
end
