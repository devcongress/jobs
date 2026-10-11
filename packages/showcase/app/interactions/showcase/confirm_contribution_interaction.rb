module Showcase
  class ConfirmContributionInteraction < Showcase::ResourceInteraction
    presents label: "Confirm", icon: Phlex::TablerIcons::Check,
      description: "Confirm you worked on this project. It will show on your profile and the project's page."

    attribute :resource

    private

    def execute
      resource.confirm!
      succeed(resource).with_message("Confirmed. #{resource.project.title} now shows on your profile.")
    end
  end
end
