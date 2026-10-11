# Sends signed-in users who have not finished onboarding (no developer
# profile and no company) to /onboarding before they can use a portal.
module RequiresOnboarding
  extend ActiveSupport::Concern

  included do
    before_action :require_onboarding
  end

  private

  def require_onboarding
    return if current_user.nil? || current_user.onboarded?

    redirect_to main_app.onboarding_path
  end
end
