module DeveloperPortal
  module Hiring
    class JobApplicationDefinition < ::Hiring::JobApplicationDefinition
      index_page_title "My applications"
      index_page_description "Jobs you've applied to and where each one stands."

      display :resume, label: "CV" do |field|
        PrivateFileLink.new(attachment: field.value, empty: "No CV attached")
      end
    end
  end
end
