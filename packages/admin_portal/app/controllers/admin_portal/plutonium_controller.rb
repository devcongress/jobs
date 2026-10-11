module AdminPortal
  # Base controller for non-resource pages (dashboard, settings, etc.).
  class PlutoniumController < ::PlutoniumController
    include AdminPortal::Concerns::Controller
  end
end
