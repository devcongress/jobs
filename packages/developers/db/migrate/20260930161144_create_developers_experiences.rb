class CreateDevelopersExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :developers_experiences do |t|
      t.belongs_to :profile, null: false, foreign_key: {to_table: :developers_profiles}
      t.belongs_to :company, null: true, foreign_key: true
      t.string :company_name, null: false
      t.string :title, null: false
      t.string :location, null: true
      t.date :started_on, null: false
      t.date :ended_on, null: true
      t.text :description, null: true

      t.timestamps
    end
  end
end
