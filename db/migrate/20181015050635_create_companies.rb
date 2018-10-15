class CreateCompanies < ActiveRecord::Migration[5.2]
  def change
    create_table :companies do |t|
      t.text :name,            null: false
      t.text :industry,        null: false
      t.text :logo,            null: false, default: ''
      t.text :website,         null: false, default: ''
      t.text :description,     null: false
      t.text :email,           null: false, unique: true
      t.text :phone,           null: false
      t.text :city,            null: false
      t.text :state_or_region, null: false
      t.text :post_code,       null: false
      t.text :country,         null: false

      t.timestamps
    end

    add_index :companies, :email, unique: true
  end
end
