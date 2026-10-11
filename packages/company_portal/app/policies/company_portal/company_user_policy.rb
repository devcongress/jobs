class CompanyPortal::CompanyUserPolicy < ::ResourcePolicy
  include CompanyPortal::ResourcePolicy

  # Core actions

  # People join through invitations (Company#invite_user), never "New".
  def create?
    false
  end

  def read?
    true
  end

  # Only owners manage the team, and never their own membership, so a
  # company always keeps the owner who's acting.
  def update?
    current_membership&.owner? && record.user_id != user.id
  end

  def destroy?
    update?
  end

  # Core attributes

  def permitted_attributes_for_update
    %i[role]
  end

  def permitted_attributes_for_read
    %i[user role created_at]
  end

  # Associations

  def permitted_associations
    %i[]
  end
end
