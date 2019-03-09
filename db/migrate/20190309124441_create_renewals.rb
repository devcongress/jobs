class CreateRenewals < ActiveRecord::Migration[5.2]
  def change
    create_table :renewals, id: false do |t|
      t.references :job,  foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.datetime :renewed_on, null: false, default: -> { 'now()' }
    end
  end
end
