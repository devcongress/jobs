class DeveloperPortal::Showcase::ProjectContributorsController < ::Showcase::ProjectContributorsController
  include DeveloperPortal::Concerns::Controller

  private

  # A contributor's `profile` is the person being credited, not the viewer, so
  # it must not be filled in from the portal's scoped profile. Records are
  # scoped in the policy instead.
  def scoped_entity_association = nil
end
