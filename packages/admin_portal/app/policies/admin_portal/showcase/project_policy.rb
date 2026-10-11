module AdminPortal
  module Showcase
    # Admins can edit or hide any project (set visibility to hidden).
    class ProjectPolicy < ::Showcase::ProjectPolicy
      include AdminPortal::ResourcePolicy

      def permitted_attributes_for_create
        [:owner, *super]
      end

      def permitted_attributes_for_read
        [:owner, :slug, *super]
      end

      def permitted_attributes_for_index
        %i[title owner visibility created_at]
      end
    end
  end
end
