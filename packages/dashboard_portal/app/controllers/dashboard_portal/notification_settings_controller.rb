module DashboardPortal
  # Which categories of notification the signed-in user gets, by email and by
  # Slack DM. Slack settings only change once Slack is connected.
  class NotificationSettingsController < PlutoniumController
    def show
    end

    def update
      settings = params.fetch(:notification_settings, {}).permit(email: [], slack: [])
      channels = current_user.slack_identity ? %w[email slack] : %w[email]
      channels.each do |channel|
        current_user.update_opt_outs!(NotificationOptOut::CATEGORIES.keys - settings[channel].to_a, via: channel)
      end
      redirect_to notification_settings_path, notice: "Notification settings saved."
    end
  end
end
