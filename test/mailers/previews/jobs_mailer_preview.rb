# Preview all emails at http://localhost:3000/rails/mailers/jobs_mailer
class JobsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/jobs_mailer/published
  def published
    JobsMailer.published
  end

end
