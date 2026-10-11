# frozen_string_literal: true

Rails.application.configure do
  config.solid_errors.connects_to = {database: {writing: :errors, reading: :errors}}
  config.solid_errors.email_from = ENV["SOLID_ERRORS_EMAIL_FROM"].presence
  config.solid_errors.email_to = ENV["SOLID_ERRORS_EMAIL_TO"].presence
  # Only deliver notifications when explicitly opted in AND both addresses are
  # configured. Enabling send_emails without a valid from/to makes Solid Errors
  # attempt to deliver malformed mail.
  config.solid_errors.send_emails = ENV["SOLID_ERRORS_SEND_EMAILS"].present? &&
    config.solid_errors.email_from.present? && config.solid_errors.email_to.present?
  config.solid_errors.username = ENV["SOLID_ERRORS_USERNAME"]
  config.solid_errors.password = ENV["SOLID_ERRORS_PASSWORD"]
end
