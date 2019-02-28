class ChangeSalaryToBeIntegerInJobs < ActiveRecord::Migration[5.2]
  def change
    change_column :jobs, :salary, 'integer USING CAST(salary AS integer)'
  end
end
