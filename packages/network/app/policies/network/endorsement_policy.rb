module Network
  # Endorsements are made from profile pages (Site::EndorsementsController).
  # Admins can review and remove them.
  class EndorsementPolicy < Network::ResourcePolicy
    def create? = false

    def read? = true

    def update? = false

    def destroy? = false

    def permitted_attributes_for_read
      %i[endorser profile skill created_at]
    end
  end
end
