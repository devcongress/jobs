module AdminPortal
  module Network
    class FollowPolicy < ::Network::FollowPolicy
      include AdminPortal::ResourcePolicy

      def destroy? = true
    end
  end
end
