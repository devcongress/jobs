class RenameCompanyOnJobs < ActiveRecord::Migration[5.2]
  def change
    rename_column :jobs, :company, :company_name
  end
end
