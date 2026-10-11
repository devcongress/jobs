# Where a job's #jobs message lives, and which status it last showed.
class AddSlackMessageToHiringJobPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :hiring_job_posts, :slack_message_ts, :string
    add_column :hiring_job_posts, :slack_message_url, :string
    add_column :hiring_job_posts, :slack_posted_status, :string
  end
end
