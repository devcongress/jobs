module Hiring
  # Applications are created only by the Apply action in the developer portal.
  # This base policy is read-only; each portal's policy grants what its
  # audience may do (CompanyPortal for the hiring team, DeveloperPortal for
  # the applicant).
  class JobApplicationPolicy < Hiring::ResourcePolicy
    def create? = false

    def read? = true

    def update? = false

    def destroy? = false

    # Hiring-team actions.
    def update_status? = false

    def reject? = false

    def add_note? = false

    def rate? = false

    def bulk_move? = false

    def kanban_move? = false

    # Applicant action.
    def withdraw? = false

    def permitted_attributes_for_read
      %i[profile job_post status cover_note created_at]
    end

    def permitted_attributes_for_index
      %i[profile job_post status created_at]
    end
  end
end
