module AdminPortal
  module Showcase
    class ProjectContributorPolicy < ::Showcase::ProjectContributorPolicy
      include AdminPortal::ResourcePolicy

      def create? = false

      def permitted_attributes_for_update
        %i[role status]
      end
    end
  end
end
