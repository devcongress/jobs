class CreateHiringJobPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :hiring_job_posts do |t|
      t.belongs_to :company, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :employment_type, null: false, default: 0
      t.integer :seniority, null: true
      t.integer :salary_min, null: true
      t.integer :salary_max, null: true
      t.string :salary_currency, null: false, default: "USD"
      t.boolean :remote_ok, null: false, default: false
      t.string :city, null: true
      t.string :country, null: true
      t.string :apply_url, null: true
      t.boolean :accepts_applications, null: false, default: true
      t.datetime :published_at, null: true
      t.datetime :expires_at, null: true
      t.datetime :filled_at, null: true
      t.datetime :archived_at, null: true

      t.timestamps
    end
    add_index :hiring_job_posts, [:published_at, :expires_at]
  end
end
