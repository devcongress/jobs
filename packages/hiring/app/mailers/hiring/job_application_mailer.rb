module Hiring
  # Keeps both sides of an in-app application informed: the company when
  # someone applies, the applicant when the company moves them along.
  class JobApplicationMailer < ::ApplicationMailer
    include PortalPathsHelper

    prepend_view_path Hiring::Engine.root.join("app/views")

    before_action do
      @application = params[:job_application]
      @job = @application.job_post
      @company = @job.company
      @profile = @application.profile
    end

    # Sent to each company user separately, so each can turn it off.
    def received
      @application_url = absolute_url(company_portal_application_path(@company, @application))
      @profile_url = absolute_url(Rails.application.routes.url_helpers.developer_page_path(handle: @profile.handle))
      categorized_mail :applications, to: params[:recipient], subject: "New applicant for #{@job.title}: #{@profile.name}"
    end

    def status_changed
      @message = params[:message]
      @application_url = absolute_url(developer_portal_application_path(@profile, @application))
      @jobs_url = absolute_url(Rails.application.routes.url_helpers.public_jobs_path)
      categorized_mail :applications, to: @profile.user, subject: @application.status_update_subject
    end
  end
end
