# Shared by the follow and endorse buttons: they need a signed-in user with a
# developer profile, acting on a profile they're allowed to see.
module NetworkActions
  extend ActiveSupport::Concern

  included do
    before_action :require_viewer_profile
  end

  private

  def require_viewer_profile
    if current_user.nil?
      redirect_to rodauth(:user).login_path, alert: "Log in to follow developers."
    elsif viewer_profile.nil?
      redirect_to new_developer_profile_path, alert: "Create a developer profile to follow and endorse people."
    end
  end

  def viewer_profile
    current_user&.developer_profile
  end

  def target_profile
    @target_profile ||= Developers::Profile.find_by!(handle: params[:handle].to_s.downcase).tap do |profile|
      raise ActiveRecord::RecordNotFound unless profile.visible_to?(current_user)
    end
  end

  def redirect_back_to_profile(**flash)
    redirect_back fallback_location: developer_page_path(handle: params[:handle]), status: :see_other, **flash
  end
end
