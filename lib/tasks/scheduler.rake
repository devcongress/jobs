desc "Inform job posters a week before their jobs are expired."
task :remind_job_owners_of_upcoming_expiration => :environment do
  Rails.logger.info "informing (via email) job posters of upcoming post expirations"
  Job.expires_in(1.week).each do |expires_soon|
  end
  Rails.logger.info "done"
end

desc "Inform job posts that their job post has expired."
task :inform_job_owners_of_expired_job_posts => :environment do
  Rails.logger.info "informing (via email) recruiters of their jobs that expired today"
  Job.expired_today.each do |expired_job|
  end
  Rails.logger.info "done"
end
