desc "Inform job posters a week before their jobs are expired."
task :remind_job_owners_of_upcoming_expiration => :environment do
  Rails.logger.info "informing (via email) job posters of upcoming post expirations"
  Job.all.each { |j| puts j.id }
  Rails.logger.info "Done."
end

desc "Inform job posters that their job post has expired."
task :inform_job_owners_of_expired_job_posts => :environment do
end
