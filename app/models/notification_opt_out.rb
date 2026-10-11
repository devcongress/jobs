# == Schema Information
#
# Table name: notification_opt_outs
#
#  id         :integer          not null, primary key
#  category   :string           not null
#  channel    :string           default("email"), not null
#  created_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  idx_on_user_id_channel_category_b4bf89541d  (user_id,channel,category) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
# A category of notification a user has turned off in one channel: email, or
# Slack DMs. Every category is on until the user opts out, from the
# notification settings page or an unsubscribe link. (Connecting Slack turns
# email off for every category, see User#slack_connected!.)
class NotificationOptOut < ApplicationRecord
  CATEGORIES = {
    "network" => {label: "Network activity", description: "When someone follows you or you become connected."},
    "applications" => {label: "Job applications", description: "New applicants on your company's jobs, and updates on jobs you've applied to."},
    "project_credits" => {label: "Project credits", description: "When someone credits you on a project, or confirms a credit you gave them."}
  }.freeze
  CHANNELS = {"email" => "emails", "slack" => "Slack DMs"}.freeze

  belongs_to :user

  validates :category, inclusion: {in: CATEGORIES.keys}
  validates :channel, inclusion: {in: CHANNELS.keys}

  # Unsubscribe links carry the user, channel and category in a signed token.
  # It never expires, so links in old emails keep working.
  def self.token_for(user, category, via:)
    verifier.generate([user.id, via.to_s, category.to_s], purpose: :unsubscribe)
  end

  # The [user, channel, category] a token was made for, or nil. Tokens made
  # before channels existed are [user_id, category] and mean email.
  def self.resolve(token)
    payload = verifier.verified(token, purpose: :unsubscribe)
    return unless payload

    user_id, channel, category = (payload.size == 2) ? [payload.first, "email", payload.last] : payload
    user = User.find_by(id: user_id) if CATEGORIES.key?(category) && CHANNELS.key?(channel)
    [user, channel, category] if user
  end

  # URL-safe, since the token goes in the link's path. The key name predates
  # the rename and must stay so old links verify.
  def self.verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.key_generator.generate_key("email_opt_out"), url_safe: true)
  end
  private_class_method :verifier
end
