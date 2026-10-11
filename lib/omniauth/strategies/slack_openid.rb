require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # Sign in with Slack (OpenID Connect). The userInfo response carries the
    # Slack user id and the workspace in https://slack.com/* claims.
    class SlackOpenid < OmniAuth::Strategies::OAuth2
      option :name, "slack_openid"
      option :scope, "openid email profile"
      option :client_options, {
        site: "https://slack.com",
        authorize_url: "https://slack.com/openid/connect/authorize",
        token_url: "https://slack.com/api/openid.connect.token",
        auth_scheme: :request_body
      }
      # `team` sends people straight to the DevCongress workspace.
      option :authorize_options, %i[scope team]

      uid { raw_info.fetch("https://slack.com/user_id") }
      info { {email: raw_info["email"], name: raw_info["name"], image: raw_info["picture"]} }
      extra { {raw_info:} }

      def raw_info
        @raw_info ||= access_token.post("/api/openid.connect.userInfo").parsed.tap do |info|
          raise CallbackError.new(:invalid_credentials, info["error"]) unless info["ok"]
        end
      end

      # Slack matches the redirect URI exactly, so leave off the query string.
      def callback_url = full_host + callback_path
    end
  end
end
