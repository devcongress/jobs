module DeveloperPortal
  module Showcase
    # The viewer's own projects (entity-scoped through `owner`).
    class ProjectPolicy < ::Showcase::ProjectPolicy
      include DeveloperPortal::ResourcePolicy
    end
  end
end
