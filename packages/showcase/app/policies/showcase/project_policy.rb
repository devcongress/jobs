module Showcase
  class ProjectPolicy < Showcase::ResourcePolicy
    def create? = true

    def read? = true

    def update? = true

    def destroy? = true

    def permitted_attributes_for_create
      %i[title summary body skills repo_url demo_url started_on ended_on visibility]
    end

    def permitted_attributes_for_read
      %i[title summary body skills repo_url demo_url started_on ended_on visibility]
    end

    def permitted_attributes_for_index
      %i[title skills visibility started_on]
    end

    def permitted_associations
      %i[contributors]
    end
  end
end
