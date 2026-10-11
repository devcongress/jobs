module Hiring
  class PublishJobPostInteraction < JobPostTransitionInteraction
    presents label: "Publish", icon: Phlex::TablerIcons::Send, description: "Make this job visible to developers"
    self.transition = :publish!

    private

    def success_message
      if resource.pending_review?
        "Submitted for review. As this is your company's first job, an admin checks it first. We'll email you when it's live."
      else
        "Job published. It stays live for #{Hiring::JobPost::VALIDITY_PERIOD.inspect}."
      end
    end
  end
end
