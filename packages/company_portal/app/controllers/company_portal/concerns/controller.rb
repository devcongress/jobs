module CompanyPortal
  module Concerns
    # Portal-wide controller customizations go here.
    # Included by both ResourceController and PlutoniumController.
    module Controller
      extend ActiveSupport::Concern
      include Plutonium::Portal::Controller
      include Plutonium::Auth::Rodauth(:user)
      include RequiresOnboarding

      # add concerns above.

      included do
        helper PortalPathsHelper
        helper_method :entity_url, :user_entities
      end

      private

      # Returns the URL to the current entity's show page.
      def entity_url
        resource_url_for(current_scoped_entity)
      end

      # Returns all entities the current user belongs to (for the entity switcher).
      def user_entities
        @user_entities ||= current_user.companies
      end
    end
  end
end
