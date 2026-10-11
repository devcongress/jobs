# Categories of email a user has turned off. No row means the email is on.
class CreateEmailOptOuts < ActiveRecord::Migration[8.1]
  def change
    create_table :email_opt_outs do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :category, null: false
      t.datetime :created_at, null: false

      t.index %i[user_id category], unique: true
    end
  end
end
