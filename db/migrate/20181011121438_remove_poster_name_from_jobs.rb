class RemovePosterNameFromJobs < ActiveRecord::Migration[5.2]
  def change
    remove_column :jobs, :poster_name, :string
  end
end
