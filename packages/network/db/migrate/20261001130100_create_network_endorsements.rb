class CreateNetworkEndorsements < ActiveRecord::Migration[8.1]
  def change
    create_table :network_endorsements do |t|
      t.belongs_to :endorser, null: false, foreign_key: {to_table: :developers_profiles, on_delete: :cascade}
      t.belongs_to :profile_skill, null: false, index: false, foreign_key: {to_table: :developers_profile_skills, on_delete: :cascade}

      t.timestamps

      t.index [:profile_skill_id, :endorser_id], unique: true
    end

    add_column :developers_profile_skills, :endorsements_count, :integer, null: false, default: 0
  end
end
