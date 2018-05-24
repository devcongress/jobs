class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs do |t|
      t.string :role
      t.string :duration
      t.string :salary
      t.string :requirements
      t.string :qualification
      t.string :perks
      t.string :company
      t.string :contact_email
      t.string :poster_name
      t.string :poster_email
      t.string :phone

      t.timestamps
    end
  end
end
