class AddFilledAtToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :filled_at, :timestamp
  end
end
