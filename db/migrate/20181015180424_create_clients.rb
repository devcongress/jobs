class CreateClients < ActiveRecord::Migration[5.2]
  def change
    create_table :clients do |t|
      t.references :company, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
