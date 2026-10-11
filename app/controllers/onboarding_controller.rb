class OnboardingController < ApplicationController
  include UserAuthenticated

  before_action :redirect_if_onboarded

  def show
    @onboarding = Onboarding.new(user: current_user)
  end

  def create
    @onboarding = Onboarding.new(user: current_user, **onboarding_params)

    if @onboarding.save
      redirect_to after_onboarding_path, notice: "Welcome! You're all set."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_onboarded
    redirect_to dashboard_portal.root_path if current_user.onboarded?
  end

  def after_onboarding_path
    profile, company = @onboarding.profile, @onboarding.company
    if profile && company
      dashboard_portal.root_path
    elsif company
      company_portal_home_path(company)
    else
      developer_portal_home_path(profile)
    end
  end

  def onboarding_params
    params.require(:onboarding)
      .permit(:developer, :first_name, :other_names, :handle, :headline, :country, :city, :visibility,
        :hiring, :company_name, :company_website, :company_country, :company_city)
      .to_h.symbolize_keys
  end
end
