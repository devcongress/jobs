module Hiring
  class ReopenJobPostInteraction < JobPostTransitionInteraction
    presents label: "Reopen", icon: Phlex::TablerIcons::Restore, description: "List this job again"
    self.transition = :reopen!
    self.success_message = "Job reopened."
  end
end
