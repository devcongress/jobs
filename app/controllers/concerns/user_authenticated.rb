# For main-app pages that need a signed-in user (outside the portals).
module UserAuthenticated
  extend ActiveSupport::Concern

  included do
    include Plutonium::Auth::Rodauth(:user)
    include PortalPathsHelper

    helper PortalPathsHelper
    # Plutonium's view helpers, needed by the Plutonium form components.
    helper Plutonium::Helpers
    before_action { rodauth(:user).require_account }
    layout "onboarding"
  end
end
