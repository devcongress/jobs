# Jobs from untrusted companies wait for admin approval before going live.
# Existing published jobs count as approved, and their companies as trusted.
class AddApprovedAtToHiringJobPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :hiring_job_posts, :approved_at, :datetime
    execute "UPDATE hiring_job_posts SET approved_at = published_at WHERE published_at IS NOT NULL"
    execute <<~SQL
      UPDATE companies SET jobs_trusted_at = CURRENT_TIMESTAMP
      WHERE jobs_trusted_at IS NULL AND id IN (SELECT company_id FROM hiring_job_posts WHERE approved_at IS NOT NULL)
    SQL
  end

  def down
    remove_column :hiring_job_posts, :approved_at
  end
end
