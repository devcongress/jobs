module Showcase
  # The confirm step of project credits: the contributor hears they've been
  # added, and the owner hears when they confirm.
  class ContributorMailer < ::ApplicationMailer
    include PortalPathsHelper

    prepend_view_path Showcase::Engine.root.join("app/views")

    before_action do
      @contributor = params[:contributor]
      @project = @contributor.project
      @owner = @project.owner
      @profile = @contributor.profile
    end

    def invited
      @confirm_url = absolute_url(developer_portal_credit_path(@profile, @contributor))
      @owner_url = absolute_url(Rails.application.routes.url_helpers.developer_page_path(handle: @owner.handle))
      categorized_mail :project_credits, to: @profile.user, subject: "#{@owner.name} credited you on #{@project.title}"
    end

    def confirmed
      @project_url = absolute_url(developer_portal_project_path(@owner, @project))
      categorized_mail :project_credits, to: @owner.user, subject: "#{@profile.name} confirmed they worked on #{@project.title}"
    end
  end
end
