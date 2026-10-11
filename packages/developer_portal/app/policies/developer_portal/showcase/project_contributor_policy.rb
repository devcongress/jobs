module DeveloperPortal
  module Showcase
    # Two views of the same records:
    # - nested under one of the viewer's projects: the owner manages who's credited;
    # - top level ("Credits"): projects other people have credited the viewer on,
    #   where they confirm or decline.
    class ProjectContributorPolicy < ::Showcase::ProjectContributorPolicy
      include DeveloperPortal::ResourcePolicy

      relation_scope do |relation|
        if parent
          default_relation_scope(relation)
        else
          skip_default_relation_scope!
          relation.where(profile: entity_scope).includes(project: :owner)
        end
      end

      # Only the project's owner adds people, from the project page.
      def create? = parent.is_a?(::Showcase::Project) && owner?

      def update? = owner?

      # The owner removes a credit; the contributor declines instead.
      def destroy? = owner?

      def confirm? = contributor? && record.pending?

      def decline? = contributor?

      def permitted_attributes_for_read
        owner? ? %i[profile role status confirmed_at] : %i[project role status confirmed_at]
      end

      def permitted_attributes_for_index
        parent ? %i[profile role status] : %i[project role status]
      end

      private

      def owner?
        project = record.is_a?(Class) ? parent : (record.project || parent)
        project.present? && project.owner_id == entity_scope.id
      end

      def contributor?
        !record.is_a?(Class) && record.profile_id == entity_scope.id
      end
    end
  end
end
