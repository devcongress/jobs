module Hiring
  # Slack DM for JobApplicationMailer#status_changed.
  class ApplicationStatusChangedDm < ::SlackDm
    self.category = :applications

    def recipient = application.profile.user

    def text = escape(application.status_update_subject)

    def blocks
      [
        section("*#{escape(application.status_update_subject)}*"),
        (section("A note from #{escape(application.company.display_name)}:\n> #{escape(params[:message]).gsub("\n", "\n> ")}") if params[:message].present?),
        application.rejected? ? button("Browse open jobs", Rails.application.routes.url_helpers.public_jobs_path) : button("View your application", developer_portal_application_path(application.profile, application))
      ].compact
    end

    private

    def application = params[:job_application]
  end
end
