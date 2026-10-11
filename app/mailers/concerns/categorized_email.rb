# Emails people can turn off by category (see NotificationOptOut::CATEGORIES).
# Each goes to one user and is skipped if they've opted out of it by email.
# Everyone else gets an unsubscribe link in the footer and the one-click
# headers mail clients use.
module CategorizedEmail
  private

  def categorized_mail(category, to:, **)
    return unless to.wants_notification?(category, via: :email)

    @email_category = NotificationOptOut::CATEGORIES.fetch(category.to_s)
    @unsubscribe_url = unsubscribe_url(token: NotificationOptOut.token_for(to, category, via: :email))
    @notification_settings_url = absolute_url(PortalPathsHelper.routes.dashboard_portal.notification_settings_path)
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    mail(to: to.email, **)
  end
end
