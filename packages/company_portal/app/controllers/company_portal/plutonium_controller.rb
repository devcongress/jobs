module CompanyPortal
  # Base controller for non-resource pages (dashboard, settings, etc.).
  class PlutoniumController < ::PlutoniumController
    include CompanyPortal::Concerns::Controller
  end
end
