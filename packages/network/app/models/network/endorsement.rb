# == Schema Information
#
# Table name: network_endorsements
#
#  id               :integer          not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  endorser_id      :integer          not null
#  profile_skill_id :integer          not null
#
# Indexes
#
#  index_network_endorsements_on_endorser_id                       (endorser_id)
#  index_network_endorsements_on_profile_skill_id_and_endorser_id  (profile_skill_id,endorser_id) UNIQUE
#
# Foreign Keys
#
#  endorser_id       (endorser_id => developers_profiles.id) ON DELETE => cascade
#  profile_skill_id  (profile_skill_id => developers_profile_skills.id) ON DELETE => cascade
#
require_relative "../network"

# A connection vouching for one of a developer's skills. Only connected
# developers may endorse each other, and nobody can endorse themselves.
class Network::Endorsement < Network::ResourceRecord
  # add concerns above.

  # add constants above.

  # add enums above.

  # add model configurations above.

  belongs_to :endorser, class_name: "Developers::Profile"
  belongs_to :profile_skill, class_name: "Developers::ProfileSkill", counter_cache: :endorsements_count
  # add belongs_to associations above.

  # add has_one associations above.

  # add has_many associations above.

  # add attachments above.

  # add scopes above.

  validates :endorser, uniqueness: {scope: :profile_skill_id, message: "has already endorsed this skill"}
  validate :endorser_is_a_connection, on: :create
  # add validations above.

  # add callbacks above.

  delegate :profile, :skill, to: :profile_skill
  # add delegations above.

  # add misc attribute macros above.

  def to_label
    "#{endorser&.name} endorsed #{skill&.name}"
  end

  # add methods above. add private methods below.

  private

  def endorser_is_a_connection
    return unless endorser && profile_skill

    if endorser.id == profile_skill.profile_id
      errors.add(:base, "You can't endorse your own skills")
    elsif !endorser.connected_to?(profile_skill.profile)
      errors.add(:base, "Only connections can endorse skills")
    end
  end
end
