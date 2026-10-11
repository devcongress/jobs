module Hiring
  class RenewJobPostInteraction < JobPostTransitionInteraction
    presents label: "Renew", icon: Phlex::TablerIcons::Refresh, description: "Put this expired job back up"
    self.transition = :renew!
    self.success_message = "Job renewed for another #{Hiring::JobPost::VALIDITY_PERIOD.inspect}."
  end
end
