# Who can see a job: members only (1) or everyone/public (2). Public by default.
class AddVisibilityToHiringJobPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :hiring_job_posts, :visibility, :integer, null: false, default: 2
  end
end
