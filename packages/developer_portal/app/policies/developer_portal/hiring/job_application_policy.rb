module DeveloperPortal
  module Hiring
    # A developer's own applications (scoped to their profile).
    class JobApplicationPolicy < ::Hiring::JobApplicationPolicy
      include DeveloperPortal::ResourcePolicy

      # Always the viewer's own applications, even when reached through a
      # nested route (parent scoping would otherwise list every applicant).
      relation_scope do |relation|
        default_relation_scope(relation).where(profile: entity_scope)
      end

      def withdraw? = record.withdrawable?

      def permitted_attributes_for_read
        %i[job_post status cover_note resume created_at]
      end

      def permitted_attributes_for_index
        %i[job_post status created_at]
      end
    end
  end
end
