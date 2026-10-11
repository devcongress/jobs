module AdminPortal
  module Hiring
    class JobPostPolicy < ::Hiring::JobPostPolicy
      include AdminPortal::ResourcePolicy

      def destroy? = true

      def approve? = record.pending_review?

      def decline? = record.pending_review?

      def permitted_attributes_for_create
        [:company, *super]
      end

      def permitted_attributes_for_read
        [:company, *super]
      end

      def permitted_attributes_for_index
        [:company, *super]
      end
    end
  end
end
