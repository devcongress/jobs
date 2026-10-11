module Network
  class FollowMailer < ::ApplicationMailer
    include PortalPathsHelper

    prepend_view_path Network::Engine.root.join("app/views")

    # Tells someone they have a new follower, or a new connection when they
    # already followed that person.
    def followed
      @follow = params[:follow]
      @follower = @follow.follower
      @followee = @follow.followee
      @connected = @follow.mutual?
      @follower_url = absolute_url(Rails.application.routes.url_helpers.developer_page_path(handle: @follower.handle))
      @network_url = absolute_url(developer_portal_network_path(@followee, tab: @connected ? "connections" : "followers"))

      subject = @connected ? "You're now connected with #{@follower.name}" : "#{@follower.name} followed you on DevCongress Connect"
      categorized_mail :network, to: @followee.user, subject:
    end
  end
end
