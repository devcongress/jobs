module Hiring
  class MarkJobPostFilledInteraction < JobPostTransitionInteraction
    presents label: "Mark as filled", icon: Phlex::TablerIcons::CircleCheck, description: "Stop showing this job"
    self.transition = :mark_filled!
    self.success_message = "Congratulations on the hire! The job is no longer listed."
  end
end
