class CreateDevelopersExperienceSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :developers_experience_skills do |t|
      t.belongs_to :experience, null: false, index: false,
        foreign_key: {to_table: :developers_experiences, on_delete: :cascade}
      t.belongs_to :profile_skill, null: false,
        foreign_key: {to_table: :developers_profile_skills, on_delete: :cascade}

      t.timestamps

      t.index [:experience_id, :profile_skill_id], unique: true
    end
  end
end
