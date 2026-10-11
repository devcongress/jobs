module Developers
  # Profiles are created during onboarding or from the dashboard, never inside
  # a portal. In the developer portal the entity is resolved through
  # `belongs_to :user`, so the only reachable profile is the viewer's own.
  class ProfilePolicy < Developers::ResourcePolicy
    def create? = false

    def read? = true

    def update? = record.user_id == user.id

    def destroy? = false

    # The show page uses the full name rather than its two parts.
    def permitted_attributes_for_read
      [:name, *(permitted_attributes_for_update - %i[first_name other_names])]
    end

    def permitted_attributes_for_update
      %i[
        first_name other_names handle headline bio
        city region country timezone remote_ok open_to_relocation
        contact_email phone contact_visibility
        website_url github_url linkedin_url x_url
        availability seniority years_experience visibility
      ]
    end

    def permitted_associations
      %i[experiences profile_skills]
    end
  end
end
