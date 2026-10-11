module AdminPortal
  # Base controller for portal resources when no feature package controller exists.
  # Add customizations to Concerns::Controller, not here.
  class ResourceController < ::ResourceController
    include AdminPortal::Concerns::Controller
  end
end
