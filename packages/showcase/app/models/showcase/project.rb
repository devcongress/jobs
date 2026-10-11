# == Schema Information
#
# Table name: showcase_projects
#
#  id         :integer          not null, primary key
#  body       :text
#  demo_url   :string
#  ended_on   :date
#  repo_url   :string
#  slug       :string           not null
#  started_on :date
#  summary    :string
#  title      :string           not null
#  visibility :integer          default("everyone"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :integer          not null
#
# Indexes
#
#  index_showcase_projects_on_owner_id                   (owner_id)
#  index_showcase_projects_on_slug                       (slug) UNIQUE
#  index_showcase_projects_on_visibility_and_updated_at  (visibility,updated_at)
#
# Foreign Keys
#
#  owner_id  (owner_id => developers_profiles.id) ON DELETE => cascade
#
require_relative "../showcase"

# Something a developer built, with the stack it used and the other
# developers who worked on it. Contributors only show once they've confirmed.
class Showcase::Project < Showcase::ResourceRecord
  # add concerns above.

  # add constants above.

  # Who can see the project. It's never more visible than its owner's profile.
  enum :visibility, {hidden: 0, members: 1, everyone: 2}, prefix: :visible_to

  # add enums above.

  # add model configurations above.

  belongs_to :owner, class_name: "Developers::Profile"
  # add belongs_to associations above.

  # add has_one associations above.

  has_many :project_skills, class_name: "Showcase::ProjectSkill", dependent: :delete_all
  has_many :skills, through: :project_skills
  has_many :contributors, class_name: "Showcase::ProjectContributor", dependent: :delete_all
  has_many :confirmed_contributors, -> { confirmed }, class_name: "Showcase::ProjectContributor"
  # add has_many associations above.

  # add attachments above.

  # Projects a viewer may see: the project's own setting and its owner's
  # profile visibility both have to allow it.
  scope :visible_to, ->(user) {
    joins(:owner).merge(Developers::Profile.visible_to(user))
      .where(visibility: user ? %i[members everyone] : :everyone)
  }

  # Owned by the profile, or credited to it with a confirmed contribution.
  scope :featuring, ->(profile) {
    where(owner: profile).or(where(id: Showcase::ProjectContributor.confirmed.where(profile:).select(:project_id)))
  }

  scope :newest, -> { order(Arel.sql("COALESCE(showcase_projects.ended_on, showcase_projects.started_on, DATE(showcase_projects.created_at)) DESC"), created_at: :desc) }

  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.strip.downcase)}%"
    left_joins(:skills).where(
      "LOWER(showcase_projects.title) LIKE :t OR LOWER(showcase_projects.summary) LIKE :t OR LOWER(skills.name) LIKE :t", t: term
    ).distinct
  }
  # add scopes above.

  validates :title, presence: true, length: {maximum: 100}
  validates :summary, length: {maximum: 200}
  validates :slug, presence: true, uniqueness: true
  validates :repo_url, :demo_url, **WebUrl.validation
  validates :ended_on, comparison: {greater_than_or_equal_to: :started_on}, allow_nil: true, if: :started_on
  validates :visibility, presence: true
  # add validations above.

  before_validation :assign_slug, on: :create
  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  def to_label
    title
  end

  def visible_to?(user)
    return true if owned_by?(user)
    return false if visible_to_hidden? || !owner.visible_to?(user)

    visible_to_everyone? || user.present?
  end

  def owned_by?(user)
    user.present? && owner&.user_id == user.id
  end

  def ongoing?
    started_on.present? && ended_on.nil?
  end

  def period
    return if started_on.nil?

    [started_on.strftime("%b %Y"), ended_on&.strftime("%b %Y") || "Present"].uniq.join(" – ")
  end

  # add methods above. add private methods below.

  private

  # The slug is fixed once created so shared links keep working when the
  # title changes.
  def assign_slug
    return if slug.present? || title.blank?

    base = title.parameterize.first(60).presence || "project"
    candidate = base
    counter = 2
    while Showcase::Project.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
