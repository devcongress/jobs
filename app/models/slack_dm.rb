# The Slack DM version of a categorised email (see NotificationOptOut::CATEGORIES).
# Subclasses set the category and define recipient, text (the notification
# preview) and blocks. A DM goes only to recipients who have connected Slack
# and haven't turned the category off there. That's checked when it's sent,
# like emails.
class SlackDm
  include PortalPathsHelper

  class_attribute :category

  attr_reader :params

  def initialize(**params)
    @params = params
  end

  def deliver_later
    SlackDmJob.perform_later(self.class.name, **params) if Slack.configured?
  end

  def deliver_now
    identity = recipient.slack_identity
    return unless identity && recipient.wants_notification?(category, via: :slack)

    Slack.client.post_message(channel: identity.uid, text:, blocks: blocks + [footer])
  end

  private

  def section(mrkdwn) = {type: "section", text: {type: "mrkdwn", text: mrkdwn}}

  def button(label, path) = {type: "actions", elements: [{type: "button", text: {type: "plain_text", text: label}, url: Slack.url(path)}]}

  def escape(text) = Slack.escape(text)

  def footer
    label = NotificationOptOut::CATEGORIES.fetch(category.to_s)[:label].downcase
    unsubscribe = Slack.url(Rails.application.routes.url_helpers.unsubscribe_path(token: NotificationOptOut.token_for(recipient, category, via: :slack)))
    {type: "context", elements: [{type: "mrkdwn", text: "<#{unsubscribe}|Turn off Slack DMs for #{label}> · <#{Slack.url(notification_settings_dashboard_path)}|Notification settings>"}]}
  end
end
