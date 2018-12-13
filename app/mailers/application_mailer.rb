class ApplicationMailer < ActionMailer::Base
  default from: 'DevCongress Jobs',
          reply_to: 'jobs@devcongress.org'

  layout 'mailer'
end
