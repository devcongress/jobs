module Network
  # Follows are made with the buttons on profiles (Site::FollowsController),
  # not through a portal form. Admins can review and remove them.
  class FollowPolicy < Network::ResourcePolicy
    def create? = false

    def read? = true

    def update? = false

    def destroy? = false

    def permitted_attributes_for_read
      %i[follower followee created_at]
    end
  end
end
