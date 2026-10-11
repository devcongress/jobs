module Showcase
  class DeclineContributionInteraction < Showcase::ResourceInteraction
    presents label: "Decline", icon: Phlex::TablerIcons::X,
      description: "Remove yourself from this project."

    attribute :resource

    private

    def execute
      resource.destroy!
      succeed(resource).with_message("You've been removed from #{resource.project.title}.")
    end
  end
end
