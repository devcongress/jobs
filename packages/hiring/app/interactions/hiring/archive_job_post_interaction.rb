module Hiring
  class ArchiveJobPostInteraction < JobPostTransitionInteraction
    presents label: "Archive", icon: Phlex::TablerIcons::Archive, description: "Hide this job for good"
    self.transition = :archive!
    self.success_message = "Job archived."
  end
end
