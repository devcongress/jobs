module AdminPortal
  module Hiring
    class JobPostDefinition < ::Hiring::JobPostDefinition
      scope :pending_review
      scope :active
    end
  end
end
