module AdminPortal
  class SkillPolicy < ::SkillPolicy
    include AdminPortal::ResourcePolicy

    def create? = true

    def update? = true

    def destroy? = true

    def permitted_attributes_for_create
      %i[name slug]
    end
  end
end
