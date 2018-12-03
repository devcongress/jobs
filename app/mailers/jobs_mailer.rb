class JobsMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.jobs_mailer.published.subject
  #
  def published
    @job = params[:job]
    @company = @job.company
    @company_people = @company.users

    subject = "New job published: #{@job.role} @ #{@company.name}"
    to = @company_people.collect { |u| u.email }

    mail(to: to, subject: subject)
  end
end
