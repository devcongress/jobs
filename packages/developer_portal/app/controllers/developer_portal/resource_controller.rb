module DeveloperPortal
  # Base controller for portal resources when no feature package controller exists.
  # Add customizations to Concerns::Controller, not here.
  class ResourceController < ::ResourceController
    include DeveloperPortal::Concerns::Controller
  end
end
