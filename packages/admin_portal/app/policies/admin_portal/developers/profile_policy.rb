module AdminPortal
  module Developers
    class ProfilePolicy < ::Developers::ProfilePolicy
      include AdminPortal::ResourcePolicy

      def create? = true

      def update? = true

      def destroy? = true

      def permitted_attributes_for_create
        [:user, *permitted_attributes_for_update]
      end

      def permitted_attributes_for_read
        [:user, *super]
      end
    end
  end
end
