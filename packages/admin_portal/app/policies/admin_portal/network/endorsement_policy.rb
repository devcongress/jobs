module AdminPortal
  module Network
    class EndorsementPolicy < ::Network::EndorsementPolicy
      include AdminPortal::ResourcePolicy

      def destroy? = true
    end
  end
end
