module Network
  # Slack DM for Network::FollowMailer#followed.
  class FollowedDm < ::SlackDm
    self.category = :network

    def recipient = follow.followee.user

    def text = escape(headline)

    def blocks
      [
        section("*#{escape(headline)}*#{"\n#{escape(follower.headline)}" if follower.headline.present?}"),
        button("View #{follower.name.split.first}'s profile", Rails.application.routes.url_helpers.developer_page_path(handle: follower.handle))
      ]
    end

    private

    def follow = params[:follow]

    def follower = follow.follower

    def headline
      follow.mutual? ? "You're now connected with #{follower.name}" : "#{follower.name} followed you on DevCongress Connect"
    end
  end
end
