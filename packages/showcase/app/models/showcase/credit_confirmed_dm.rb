module Showcase
  # Slack DM for ContributorMailer#confirmed.
  class CreditConfirmedDm < ::SlackDm
    self.category = :project_credits

    def recipient = contributor.owner.user

    def text = escape(headline)

    def blocks
      [section("*#{escape(headline)}*"), button("View the project", developer_portal_project_path(contributor.owner, contributor.project))]
    end

    private

    def contributor = params[:contributor]

    def headline = "#{contributor.profile.name} confirmed they worked on #{contributor.project.title}"
  end
end
