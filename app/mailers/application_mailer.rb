class ApplicationMailer < ActionMailer::Base
  default from: 'jobs@devcongress.org',
          reply_to: 'jobs@devcongress.org'

  layout 'mailer'
end
