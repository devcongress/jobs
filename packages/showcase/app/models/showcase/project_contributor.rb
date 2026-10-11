# == Schema Information
#
# Table name: showcase_project_contributors
#
#  id           :integer          not null, primary key
#  confirmed_at :datetime
#  role         :string
#  status       :integer          default("pending"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  profile_id   :integer          not null
#  project_id   :integer          not null
#
# Indexes
#
#  idx_on_project_id_profile_id_42ba9b7f27            (project_id,profile_id) UNIQUE
#  index_showcase_project_contributors_on_profile_id  (profile_id)
#
# Foreign Keys
#
#  profile_id  (profile_id => developers_profiles.id) ON DELETE => cascade
#  project_id  (project_id => showcase_projects.id) ON DELETE => cascade
#
require_relative "../showcase"

# Someone the owner credits on a project. The owner adds them by handle and
# they confirm; until then the credit stays off public pages, so nobody can
# claim work with someone who didn't agree to it.
class Showcase::ProjectContributor < Showcase::ResourceRecord
  # add concerns above.

  # add constants above.

  enum :status, {pending: 0, confirmed: 1}

  # add enums above.

  # add model configurations above.

  belongs_to :project, class_name: "Showcase::Project"
  # Presence is checked in #profile_present, so the error lands on the handle field.
  belongs_to :profile, class_name: "Developers::Profile", optional: true
  # add belongs_to associations above.

  # add has_one associations above.

  # add has_many associations above.

  # add attachments above.

  # add scopes above.

  validates :profile, uniqueness: {scope: :project_id, message: "is already on this project"}
  validates :role, length: {maximum: 60}
  validate :profile_present
  validate :not_the_owner
  # add validations above.

  after_create_commit -> {
    Showcase::ContributorMailer.with(contributor: self).invited.deliver_later
    Showcase::CreditInvitedDm.new(contributor: self).deliver_later
  }
  # add callbacks above.

  delegate :owner, to: :project
  # add delegations above.

  # The owner names a contributor by their @handle. Hidden profiles can't be
  # added.
  attribute :handle, :string

  # add misc attribute macros above.

  def handle=(value)
    super
    normalized = value.to_s.strip.downcase.delete_prefix("@")
    self.profile = normalized.present? ? Developers::Profile.where.not(visibility: :hidden).find_by(handle: normalized) : nil
    @handle_not_found = normalized.present? && profile.nil?
  end

  def to_label
    profile&.name || "Contributor"
  end

  def confirm!
    return if confirmed?

    update!(status: :confirmed, confirmed_at: Time.current)
    Showcase::ContributorMailer.with(contributor: self).confirmed.deliver_later
    Showcase::CreditConfirmedDm.new(contributor: self).deliver_later
  end

  # add methods above. add private methods below.

  private

  def profile_present
    if @handle_not_found
      errors.add(:handle, "doesn't match a developer on DevCongress Connect")
    elsif profile.nil?
      errors.add(:handle, "can't be blank")
    end
  end

  def not_the_owner
    errors.add(:handle, "is you. You're already on the project as its owner") if profile && project && profile_id == project.owner_id
  end
end
