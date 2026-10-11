# Lets an onboarded user who skipped it create their developer profile.
class DeveloperProfileSetupsController < ::PlutoniumController
  include UserAuthenticated
  include RequiresOnboarding

  before_action :redirect_if_profile_exists

  def new
    @profile = current_user.build_developer_profile(handle: Onboarding.new(user: current_user).handle, visibility: :everyone)
  end

  def create
    @profile = current_user.build_developer_profile(profile_params)

    if @profile.save
      redirect_to developer_portal_home_path(@profile), notice: "Your developer profile is ready."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_profile_exists
    redirect_to developer_portal_home_path(current_user.developer_profile) if current_user.developer_profile
  end

  def profile_params
    params.require(:developers_profile).permit(:first_name, :other_names, :handle, :headline, :country, :city, :visibility)
  end
end
