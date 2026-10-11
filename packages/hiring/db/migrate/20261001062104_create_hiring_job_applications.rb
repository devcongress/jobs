class CreateHiringJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :hiring_job_applications do |t|
      t.belongs_to :job_post, null: false, foreign_key: {to_table: :hiring_job_posts}
      t.belongs_to :profile, null: false, foreign_key: {to_table: :developers_profiles}
      t.text :cover_note, null: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :hiring_job_applications, [:job_post_id, :profile_id], unique: true
  end
end
