module Developers
  class ExperiencePolicy < Developers::ResourcePolicy
    def create? = true

    def read? = true

    def update? = true

    def destroy? = true

    def permitted_attributes_for_create
      %i[title company_name location started_on ended_on description]
    end

    def permitted_attributes_for_read
      permitted_attributes_for_create
    end

    def permitted_attributes_for_index
      %i[title company_name location started_on ended_on]
    end
  end
end
