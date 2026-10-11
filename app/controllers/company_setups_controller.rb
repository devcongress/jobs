# Lets an onboarded user set up a company. They become its owner; their
# developer profile (if any) is unaffected.
class CompanySetupsController < ::PlutoniumController
  include UserAuthenticated
  include RequiresOnboarding

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)

    saved = ActiveRecord::Base.transaction do
      @company.save && @company.company_users.create!(user: current_user, role: :owner)
    end

    if saved
      redirect_to company_portal_home_path(@company), notice: "#{@company.name} is ready."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :website, :country, :city)
  end
end
