module Showcase
  class ProjectContributorPolicy < Showcase::ResourcePolicy
    def create? = true

    def read? = true

    def update? = true

    def destroy? = true

    def confirm? = false

    def decline? = false

    def permitted_attributes_for_create
      %i[handle role]
    end

    def permitted_attributes_for_update
      %i[role]
    end

    def permitted_attributes_for_read
      %i[project profile role status confirmed_at]
    end
  end
end
