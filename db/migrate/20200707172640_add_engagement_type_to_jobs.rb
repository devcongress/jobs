class AddEngagementTypeToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :engagement_type, :text, null:false, default: ''
  end
end
