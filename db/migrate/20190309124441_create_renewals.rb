class CreateRenewals < ActiveRecord::Migration[5.2]
  def change
    reversible do |m|
      m.up do
        create_table :renewals, id: false do |t|
          t.references :job,  foreign_key: true, null: false
          t.timestamp :renewed_on, null: false, default: -> { 'now()' }
        end

        execute <<-SQL
    INSERT INTO renewals ( job_id, renewed_on) SELECT id, created_at FROM jobs;
        SQL
      end

      m.down do
        drop_table :renewals
      end
    end
  end
end
