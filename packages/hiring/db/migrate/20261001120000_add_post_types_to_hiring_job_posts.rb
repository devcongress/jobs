# Jobs, gigs and internships: what the pay is per, whether it's paid at all,
# and how long the work lasts.
class AddPostTypesToHiringJobPosts < ActiveRecord::Migration[8.1]
  def change
    change_table :hiring_job_posts do |t|
      t.integer :pay_period, null: false, default: 0   # year, month, day, hour, fixed
      t.boolean :paid, null: false, default: true      # internships can be unpaid
      t.string :duration, null: true                  # free text: "2 weeks", "3 months"
      t.date :starts_on, null: true
    end
  end
end
