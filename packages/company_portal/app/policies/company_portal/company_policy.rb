class CompanyPortal::CompanyPolicy < ::CompanyPolicy
  include CompanyPortal::ResourcePolicy

  def update?
    current_membership&.owner?
  end

  def destroy?
    false
  end

  # The slug stays fixed so existing company URLs keep working.
  def permitted_attributes_for_read
    [:name, :website, :description, :country, :city]
  end

  def permitted_attributes_for_update
    permitted_attributes_for_read
  end

  def permitted_associations
    []
  end
end
