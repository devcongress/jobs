module Developers
  class ProfileSkillPolicy < Developers::ResourcePolicy
    def create? = true

    def read? = true

    def update? = true

    def destroy? = true

    def permitted_attributes_for_create
      %i[skill level years]
    end

    def permitted_attributes_for_read
      [*permitted_attributes_for_create, :endorsements_count]
    end
  end
end
