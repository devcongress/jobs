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
    subject = "New job published: #{@job.role} @ #{@company.name}"

    mail(to: to, subject: subject)
  end

  def renewed
    @job = params[:job]
    @company = @job.company
    @company_people = @company.users.pluck(:email)

    subject = "🎉#{@job.title} has been renewed for another #{Job.validity_period} days"
    to = @company.users.pluck(:email)

    mail(to: to, subject: subject)
  end
end
