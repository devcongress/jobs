module Hiring
  # Emails for the first-job review: admins are asked to review, and each
  # company user hears back when its job is approved or declined.
  class JobReviewMailer < ::ApplicationMailer
    include PortalPathsHelper

    prepend_view_path Hiring::Engine.root.join("app/views")

    before_action do
      @job = params[:job_post]
      @company = @job.company
    end

    def review_requested
      recipients = Admin.verified.pluck(:email)
      return if recipients.empty?

      @review_url = absolute_url(PortalPathsHelper.routes.admin_portal.hiring_job_post_path(@job))
      mail to: recipients, subject: "Review needed: #{@job.title} at #{@company.display_name}"
    end

    def approved
      @job_url = absolute_url(Rails.application.routes.url_helpers.public_job_path(@job))
      @dashboard_url = absolute_url(company_portal_home_path(@company))
      mail to: params[:recipient].email, subject: "Your #{@job.kind_noun} is live: #{@job.title}"
    end

    def declined
      @reason = params[:reason]
      @edit_url = absolute_url(PortalPathsHelper.routes.company_portal.company_scoped_hiring_job_post_path(company_scoped: @company, id: @job))
      mail to: params[:recipient].email, subject: "Changes needed before #{@job.title} goes live"
    end
  end
end
