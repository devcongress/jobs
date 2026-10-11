module CompanyPortal
  module Hiring
    class JobPostDefinition < ::Hiring::JobPostDefinition
      index_page_description "Jobs, gigs and internships. Draft them, then publish when they're ready."

      scope :active
      scope :drafts
    end
  end
end
