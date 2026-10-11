class CreateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :skills, :name, unique: true
    add_index :skills, :slug, unique: true
  end
end
