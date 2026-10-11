module CompanyPortal
  module Hiring
    # The hiring team working through applicants to their company's jobs.
    class JobApplicationPolicy < ::Hiring::JobApplicationPolicy
      include CompanyPortal::ResourcePolicy

      def update_status? = active?

      def reject? = active? && !record.rejected?

      def add_note? = true

      def rate? = active?

      def bulk_move? = active?

      # Drag-and-drop on the board. Withdrawn applicants stay where they are.
      def kanban_move? = active?

      def export_csv? = true

      def permitted_attributes_for_read
        %i[profile job_post status rating cover_note created_at]
      end

      def permitted_attributes_for_index
        %i[profile job_post status rating_stars created_at]
      end

      def permitted_attributes_for_export
        %i[profile email job_post status rating created_at]
      end

      private

      # Class-level checks (e.g. "can this user drag on the board at all?")
      # have no record to inspect.
      def active? = !(record.is_a?(::Hiring::JobApplication) && record.withdrawn?)
    end
  end
end
