class ResourcePolicy < Plutonium::Resource::Policy
  def create?
    true
  end

  def read?
    true
  end

  private

  def current_membership
    return unless entity_scope && user

    @current_membership ||= CompanyUser.find_by(company: entity_scope, user: user)
  end
end
