class CreateDevelopersProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :developers_profiles do |t|
      t.belongs_to :user, null: false, foreign_key: true, index: {unique: true}
      t.string :handle, null: false
      t.string :name, null: false
      t.string :headline, null: true
      t.text :bio, null: true
      t.string :city, null: true
      t.string :region, null: true
      t.string :country, null: true
      t.string :timezone, null: true
      t.boolean :remote_ok, null: false, default: true
      t.boolean :open_to_relocation, null: false, default: false
      t.string :contact_email, null: true
      t.string :phone, null: true
      t.string :website_url, null: true
      t.string :github_url, null: true
      t.string :linkedin_url, null: true
      t.string :x_url, null: true
      t.integer :availability, null: false, default: 1
      t.integer :seniority, null: true
      t.integer :years_experience, null: true
      t.integer :contact_visibility, null: false, default: 1
      t.boolean :listed, null: false, default: true

      t.timestamps
    end
    add_index :developers_profiles, :handle, unique: true
    add_index :developers_profiles, [:listed, :availability]
    add_index :developers_profiles, :country
  end
end
