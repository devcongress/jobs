desc "Inform job posters a week before their jobs are expired."
task :remind_job_owners_of_upcoming_expiration => :environment do
  Rails.logger.info "informing (via email) job posters of upcoming post expirations"
  Job.expires_soon.each do |expires_soon|
    JobMailer.with(job: expires_soon).expires_soon.deliver_now
  end
  Rails.logger.info "done"
end

desc "Inform job posters that their job post has expired."
task :inform_job_owners_of_expired_job_posts => :environment do
  Rails.logger.info "informing (via email) recruiters of their jobs that expired today"
  Job.expired_today.each do |expired_job|
    JobMailer.with(job: expired_job).expired.deliver_now
  end
  Rails.logger.info "done"
end
