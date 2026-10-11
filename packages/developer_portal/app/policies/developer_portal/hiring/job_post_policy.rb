module DeveloperPortal
  module Hiring
    # Developers browse every company's active jobs and can apply. Jobs aren't
    # owned by the profile, so this skips entity scoping and shows only live jobs.
    class JobPostPolicy < ::Hiring::JobPostPolicy
      include DeveloperPortal::ResourcePolicy

      relation_scope do |relation|
        skip_default_relation_scope!
        relation.active.includes(:company)
      end

      def create? = false

      def update? = false

      def destroy? = false

      def publish? = false

      def renew? = false

      def mark_filled? = false

      def reopen? = false

      def archive? = false

      def apply?
        record.accepts_applications? && record.active? && record.company.personal_owner_id != entity_scope.user_id &&
          !record.job_applications.exists?(profile: entity_scope)
      end

      def permitted_attributes_for_read
        %i[title company type_label seniority location pay timing description apply_url published_at]
      end

      def permitted_attributes_for_index
        %i[title company type_label location pay]
      end

      def permitted_associations
        %i[]
      end
    end
  end
end
