module DashboardPortal
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
        helper SlackHelper
      end
    end
  end
end
