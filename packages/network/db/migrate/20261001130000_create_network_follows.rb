class CreateNetworkFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :network_follows do |t|
      t.belongs_to :follower, null: false, index: false, foreign_key: {to_table: :developers_profiles, on_delete: :cascade}
      t.belongs_to :followee, null: false, foreign_key: {to_table: :developers_profiles, on_delete: :cascade}

      t.timestamps

      t.index [:follower_id, :followee_id], unique: true
      t.check_constraint "follower_id <> followee_id", name: "network_follows_not_self"
    end
  end
end
