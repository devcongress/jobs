class CreateHiringApplicationNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :hiring_application_notes do |t|
      t.belongs_to :job_application, null: false, foreign_key: {to_table: :hiring_job_applications, on_delete: :cascade}
      t.belongs_to :author, null: true, foreign_key: {to_table: :users, on_delete: :nullify}
      t.integer :kind, null: false, default: 0
      t.text :body, null: true
      t.string :from_status, null: true
      t.string :to_status, null: true

      t.timestamps

      t.index [:job_application_id, :created_at]
    end
  end
end
