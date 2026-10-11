# Individuals post gigs and jobs through a personal posting space: a company
# row owned by one user, shown publicly as that person.
class AddPersonalOwnerToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_reference :companies, :personal_owner, null: true, foreign_key: {to_table: :users, on_delete: :cascade},
      index: {unique: true}
  end
end
