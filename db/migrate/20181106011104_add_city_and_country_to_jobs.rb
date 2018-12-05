class AddCityAndCountryToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :city, :string, null: false, default: ''
    add_column :jobs, :country, :string, null: false, default: ''
  end
end
