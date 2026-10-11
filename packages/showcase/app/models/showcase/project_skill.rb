# == Schema Information
#
# Table name: showcase_project_skills
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#  skill_id   :integer          not null
#
# Indexes
#
#  index_showcase_project_skills_on_project_id_and_skill_id  (project_id,skill_id) UNIQUE
#  index_showcase_project_skills_on_skill_id                 (skill_id)
#
# Foreign Keys
#
#  project_id  (project_id => showcase_projects.id) ON DELETE => cascade
#  skill_id    (skill_id => skills.id)
#
require_relative "../showcase"

class Showcase::ProjectSkill < Showcase::ResourceRecord
  belongs_to :project, class_name: "Showcase::Project"
  belongs_to :skill

  validates :skill, uniqueness: {scope: :project_id}
end
