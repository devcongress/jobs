module DashboardPortal
  # Base controller for non-resource pages (dashboard, settings, etc.).
  class PlutoniumController < ::PlutoniumController
    include DashboardPortal::Concerns::Controller
  end
end
