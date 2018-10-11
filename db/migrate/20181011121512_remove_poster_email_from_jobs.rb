class RemovePosterEmailFromJobs < ActiveRecord::Migration[5.2]
  def change
    remove_column :jobs, :poster_email, :string
  end
end
