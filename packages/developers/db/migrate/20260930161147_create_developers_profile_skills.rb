class CreateDevelopersProfileSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :developers_profile_skills do |t|
      t.belongs_to :profile, null: false, foreign_key: {to_table: :developers_profiles}
      t.belongs_to :skill, null: false, foreign_key: true
      t.integer :level, null: true
      t.integer :years, null: true

      t.timestamps
    end
    add_index :developers_profile_skills, [:profile_id, :skill_id], unique: true
  end
end
