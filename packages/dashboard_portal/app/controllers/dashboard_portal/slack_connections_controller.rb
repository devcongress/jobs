module DashboardPortal
  # Unlinks Slack. Connecting goes through Rodauth's Slack sign-in.
  class SlackConnectionsController < PlutoniumController
    def destroy
      if current_user.slack_identity.nil?
        redirect_to notification_settings_path, notice: "Slack isn't connected."
      elsif current_user.can_sign_in_without_slack?
        current_user.disconnect_slack!
        redirect_to notification_settings_path, notice: "Slack disconnected. Notifications you had on in Slack now come by email."
      else
        redirect_to notification_settings_path, alert: "Set a password first so you can still sign in."
      end
    end
  end
end
