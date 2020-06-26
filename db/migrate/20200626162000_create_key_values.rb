# frozen_string_literal: true

class CreateKeyValues < ActiveRecord::Migration[5.2]
  def change
    create_table :key_values do |t|
      t.text :key, null: false
      t.text :sub_key, null: false
      t.jsonb :data, null: false

      t.timestamps
    end

    add_index :key_values, %i[key sub_key], unique: true
  end
end
