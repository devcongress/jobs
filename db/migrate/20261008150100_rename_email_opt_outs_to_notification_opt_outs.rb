# Opt-outs now apply per channel: email, or Slack DMs.
class RenameEmailOptOutsToNotificationOptOuts < ActiveRecord::Migration[8.1]
  def change
    rename_table :email_opt_outs, :notification_opt_outs
    add_column :notification_opt_outs, :channel, :string, null: false, default: "email"
    remove_index :notification_opt_outs, %i[user_id category], unique: true
    add_index :notification_opt_outs, %i[user_id channel category], unique: true
  end
end
