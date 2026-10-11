class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :website
      t.text :description
      t.string :city
      t.string :country

      t.timestamps
    end
    add_index :companies, :name, unique: true
    add_index :companies, :slug, unique: true
  end
end
