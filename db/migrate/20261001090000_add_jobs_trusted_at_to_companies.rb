# A company is trusted once an admin approves its first job; after that its
# jobs publish without review.
class AddJobsTrustedAtToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :jobs_trusted_at, :datetime
  end
end
