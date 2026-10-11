module Hiring
  class ApproveJobPostInteraction < JobPostTransitionInteraction
    presents label: "Approve", icon: Phlex::TablerIcons::CircleCheck, description: "Make this job live and trust the company"
    self.transition = :approve!
    self.success_message = "Approved. The job is live and the company is now trusted."
  end
end
