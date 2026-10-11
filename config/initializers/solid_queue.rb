# frozen_string_literal: true

Rails.application.configure do
  # Tests use Active Job's test adapter so they can assert on enqueued jobs/emails.
  config.active_job.queue_adapter = Rails.env.test? ? :test : :solid_queue
  config.solid_queue.connects_to = {database: {writing: :queue}}
  config.solid_queue.silence_polling = true
end
