class RemoveIndustriesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :industries, if_exists: true
  end
end
