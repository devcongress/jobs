class AddRemoteOkToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :remote_ok, :boolean, null: false, default: true
  end
end
