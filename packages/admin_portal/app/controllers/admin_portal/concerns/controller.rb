module AdminPortal
  module Concerns
    # Portal-wide controller customizations go here.
    # Included by both ResourceController and PlutoniumController.
    module Controller
      extend ActiveSupport::Concern
      include Plutonium::Portal::Controller
      include Plutonium::Auth::Rodauth(:admin)
      # add concerns above.
    end
  end
end
