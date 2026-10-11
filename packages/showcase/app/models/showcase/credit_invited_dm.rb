module Showcase
  # Slack DM for ContributorMailer#invited.
  class CreditInvitedDm < ::SlackDm
    self.category = :project_credits

    def recipient = contributor.profile.user

    def text = escape(headline)

    def blocks
      [
        section("*#{escape(headline)}*\nConfirm it if you worked on it and it shows on your profile."),
        button("Confirm or decline", developer_portal_credit_path(contributor.profile, contributor))
      ]
    end

    private

    def contributor = params[:contributor]

    def headline = "#{contributor.owner.name} credited you on #{contributor.project.title}"
  end
end
