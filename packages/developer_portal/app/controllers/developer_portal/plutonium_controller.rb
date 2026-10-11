module DeveloperPortal
  # Base controller for non-resource pages (dashboard, settings, etc.).
  class PlutoniumController < ::PlutoniumController
    include DeveloperPortal::Concerns::Controller
  end
end
