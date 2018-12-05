class AddApplyLinkToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :apply_link, :text, null: false, default: ''
  end
end
