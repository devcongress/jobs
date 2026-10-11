# Whether the Slack parts of the UI have anything to offer. Each piece of Slack
# switches on with its env vars (see Slack), so a partly set up app shows
# only what works.
module SlackHelper
  # "Connect Slack" works: the slack provider is registered (UserRodauthPlugin).
  def slack_sign_in? = rodauth(:user).omniauth_providers.include?(:slack)

  # The Slack card has something to offer: joining, connecting, or both.
  def slack_available? = Slack.invite_url.present? || slack_sign_in?
end
