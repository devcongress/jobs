module Hiring
  # Slack DM for JobApplicationMailer#received, one per company user.
  class ApplicationReceivedDm < ::SlackDm
    self.category = :applications

    def recipient = params[:recipient]

    def text = escape(headline)

    def blocks
      [
        section("*#{escape(headline)}*#{"\n#{escape(profile.headline)}" if profile.headline.present?}"),
        button("Review application", company_portal_application_path(application.job_post.company, application))
      ]
    end

    private

    def application = params[:job_application]

    def profile = application.profile

    def headline = "New applicant for #{application.job_post.title}: #{profile.name}"
  end
end
