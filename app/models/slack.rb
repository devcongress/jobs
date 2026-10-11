# The DevCongress Slack workspace. Each piece switches itself on when its env
# vars are set: SLACK_BOT_TOKEN for #jobs posts and DMs, SLACK_JOBS_CHANNEL_ID
# for #jobs, SLACK_CLIENT_ID/SECRET and SLACK_TEAM_ID for sign-in (see
# UserRodauthPlugin), SLACK_INVITE_URL and SLACK_WORKSPACE_URL for links.
module Slack
  # Connection failures worth retrying.
  NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError, Unavailable].freeze

  class << self
    attr_writer :client, :jobs_channel

    def client
      @client ||= (Client.new(ENV["SLACK_BOT_TOKEN"]) if ENV["SLACK_BOT_TOKEN"].present?)
    end

    def jobs_channel
      @jobs_channel ||= ENV["SLACK_JOBS_CHANNEL_ID"].presence
    end

    def team_id = ENV["SLACK_TEAM_ID"].presence

    def invite_url = ENV["SLACK_INVITE_URL"].presence

    def workspace_url = ENV["SLACK_WORKSPACE_URL"].presence

    def configured? = client.present?

    def posts_jobs? = configured? && jobs_channel.present?

    # Turns an app path (including portal engine paths) into a full URL.
    def url(path)
      Rails.application.routes.url_helpers.root_url(**ActionMailer::Base.default_url_options).chomp("/") + path
    end

    # Slack mrkdwn treats &, < and > as control characters.
    def escape(text)
      text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end
  end
end
