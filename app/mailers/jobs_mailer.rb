class JobsMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.jobs_mailer.published.subject
  #
  def published
    @job = params[:job]
    @company = @job.company

    to = @company.users.pluck(:email)
    subject = "🎊 [Jobs] Your new job, #{@job.title}, has been published"

    mail(to: to, subject: subject)
  end

  def renewed
    @job = params[:job]
    @company = @job.company

    subject = "🎉 [Jobs] #{@job.title} has been renewed for another #{Job.validity_period} days"
    to = @company.users.pluck(:email)

    mail(to: to, subject: subject)
  end

  def expires_soon
    @job = params[:job]
    @company = @job.company

    subject = "📯 [Jobs] #{@job.title} expires in #{Job.days_to_expiry} days"
    to = @company.users.pluck(:email)

    mail(to: to, subject: subject)
  end

  def expired
    @job = params[:job]
    @company = @job.company

    subject = "[Jobs] #{@job.title} has expired today!"
    to = @company.users.pluck(:email)

    mail(to: to, subject: subject)
  end
end
