class AddPipelineFieldsToHiringJobApplications < ActiveRecord::Migration[8.1]
  def change
    change_table :hiring_job_applications do |t|
      t.position                       # order within a status column on the board
      t.integer :rating, null: true    # the hiring team's 1-5 rating
      t.datetime :status_changed_at, null: true

      t.index [:status, :position]
    end

    up_only do
      execute <<~SQL
        UPDATE hiring_job_applications
        SET position = id, status_changed_at = updated_at
      SQL
    end
  end
end
