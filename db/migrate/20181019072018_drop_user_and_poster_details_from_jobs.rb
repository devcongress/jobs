class DropUserAndPosterDetailsFromJobs < ActiveRecord::Migration[5.2]
  def change
    remove_column :jobs, :user_id,       :integer
    remove_column :jobs, :company_name,  :string
    remove_column :jobs, :contact_email, :string
    remove_column :jobs, :phone,         :string

    [
      :company_id,
      :role,
      :salary,
      :requirements,
      :qualification
    ].each do |col|
      change_column_null :jobs, col, false
    end
  end
end
