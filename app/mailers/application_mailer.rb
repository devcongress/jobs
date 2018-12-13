class ApplicationMailer < ActionMailer::Base
  default from: 'DevCongress Jobs <jobs@devcongress.org>',
          reply_to: 'jobs@devcongress.org'

  layout 'mailer'
end
