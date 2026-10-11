class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "DevCongress Connect <no-reply@example.com>")
  layout "mailer"
  helper EmailHelper
  include CategorizedEmail

  private

  # Turns an app path (including portal engine paths) into a full URL.
  def absolute_url(path)
    Rails.application.routes.url_helpers.root_url(**default_url_options).chomp("/") + path
  end
end
