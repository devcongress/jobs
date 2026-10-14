class AddContentToSkills < ActiveRecord::Migration[8.1]
  def change
    add_column :skills, :category, :string
    add_column :skills, :description, :text
    add_column :skills, :website_url, :string
    add_column :skills, :source_url, :string
    add_column :skills, :why_description, :text
    add_column :skills, :company_examples, :json, null: false, default: []
    add_column :skills, :content_curated, :boolean, null: false, default: false
    add_index :skills, :category
    add_index :skills, :content_curated
  end
end
