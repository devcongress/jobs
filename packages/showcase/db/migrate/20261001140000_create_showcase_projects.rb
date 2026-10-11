class CreateShowcaseProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :showcase_projects do |t|
      t.belongs_to :owner, null: false, foreign_key: {to_table: :developers_profiles, on_delete: :cascade}
      t.string :title, null: false
      t.string :slug, null: false
      t.string :summary
      t.text :body
      t.string :repo_url
      t.string :demo_url
      t.date :started_on
      t.date :ended_on
      t.integer :visibility, null: false, default: 2

      t.timestamps

      t.index :slug, unique: true
      t.index [:visibility, :updated_at]
    end

    create_table :showcase_project_skills do |t|
      t.belongs_to :project, null: false, index: false, foreign_key: {to_table: :showcase_projects, on_delete: :cascade}
      t.belongs_to :skill, null: false, foreign_key: true

      t.timestamps

      t.index [:project_id, :skill_id], unique: true
    end

    create_table :showcase_project_contributors do |t|
      t.belongs_to :project, null: false, index: false, foreign_key: {to_table: :showcase_projects, on_delete: :cascade}
      t.belongs_to :profile, null: false, foreign_key: {to_table: :developers_profiles, on_delete: :cascade}
      t.string :role
      t.integer :status, null: false, default: 0
      t.datetime :confirmed_at

      t.timestamps

      t.index [:project_id, :profile_id], unique: true
    end
  end
end
