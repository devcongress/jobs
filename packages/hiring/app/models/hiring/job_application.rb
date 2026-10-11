# == Schema Information
#
# Table name: hiring_job_applications
#
#  id                :integer          not null, primary key
#  cover_note        :text
#  position          :decimal(16, 8)
#  rating            :integer
#  status            :integer          default("submitted"), not null
#  status_changed_at :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  job_post_id       :integer          not null
#  profile_id        :integer          not null
#
# Indexes
#
#  index_hiring_job_applications_on_job_post_id                 (job_post_id)
#  index_hiring_job_applications_on_job_post_id_and_profile_id  (job_post_id,profile_id) UNIQUE
#  index_hiring_job_applications_on_profile_id                  (profile_id)
#  index_hiring_job_applications_on_status_and_position         (status,position)
#
# Foreign Keys
#
#  job_post_id  (job_post_id => hiring_job_posts.id)
#  profile_id   (profile_id => developers_profiles.id)
#
require_relative "../hiring"

# A developer applying to a job through the app.
class Hiring::JobApplication < Hiring::ResourceRecord
  include Plutonium::Positioning::Model
  include ActiveShrine::Model

  # Statuses the applicant hears about by email.
  NOTIFY_STATUSES = %w[reviewing shortlisted rejected hired].freeze
  # How each status reads in the hiring team's pipeline.
  STAGE_LABELS = {
    "submitted" => "New", "reviewing" => "Reviewing", "shortlisted" => "Shortlisted",
    "hired" => "Hired", "rejected" => "Rejected", "withdrawn" => "Withdrawn"
  }.freeze
  RATINGS = (1..5)

  enum :status, {submitted: 0, reviewing: 1, shortlisted: 2, rejected: 3, hired: 4, withdrawn: 5}

  positioned_on :position, scope: :status

  belongs_to :job_post, class_name: "Hiring::JobPost"
  belongs_to :profile, class_name: "Developers::Profile"
  has_one :company, through: :job_post

  has_many :notes, -> { order(:created_at, :id) }, class_name: "Hiring::ApplicationNote", inverse_of: :job_application, dependent: :delete_all

  has_one_attached :resume, uploader: ::ResumeUploader

  scope :open, -> { where(status: %i[submitted reviewing shortlisted]) }
  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.strip)}%"
    joins(:profile).where(
      "developers_profiles.name LIKE :q OR developers_profiles.handle LIKE :q OR developers_profiles.headline LIKE :q",
      q: term
    )
  }

  validates :profile, uniqueness: {scope: :job_post_id, message: "has already applied to this job"}
  validates :cover_note, length: {maximum: 5_000}
  validates :rating, inclusion: {in: RATINGS}, allow_nil: true
  validate :job_accepts_applications, on: :create

  before_save { self.status_changed_at = Time.current if will_save_change_to_status? }
  after_update :log_status_change, if: :saved_change_to_status?
  after_create_commit :notify_company
  after_update_commit :notify_applicant, if: -> { saved_change_to_status? && status.in?(NOTIFY_STATUSES) }

  # An optional note to the applicant, sent with the status-change email.
  attribute :status_message, :string

  def to_label
    "#{profile.name} for #{job_post.title}"
  end

  def stage_label = STAGE_LABELS.fetch(status)

  def rating_stars = rating && (("★" * rating) + ("☆" * (RATINGS.max - rating)))

  # Where the hiring team can reach the applicant: applying shares contact
  # details with the company, whatever the profile's public setting.
  def applicant_email = profile.contact_email.presence || profile.user.email

  def withdrawable? = submitted? || reviewing? || shortlisted?

  def withdraw!
    update!(status: :withdrawn)
  end

  # Moves the applicant to a stage, optionally with a message for them.
  def move_to!(new_status, message: nil)
    update!(status: new_status, status_message: message.presence)
  end

  def add_note!(body, author:)
    notes.create!(kind: :note, body:, author:)
  end

  # Headline for telling the applicant about their new status (email and Slack).
  def status_update_subject
    case status
    when "shortlisted" then "You're on the shortlist for #{job_post.title}"
    when "hired" then "#{company.display_name} wants to hire you"
    else "An update on your application to #{company.display_name}"
    end
  end

  private

  def log_status_change
    from, to = saved_change_to_status
    notes.create!(kind: :status_change, from_status: from, to_status: to, author: Current.user, body: status_message.presence)
  end

  def notify_company
    job_post.company.users.verified.find_each do |recipient|
      Hiring::JobApplicationMailer.with(job_application: self, recipient:).received.deliver_later
      Hiring::ApplicationReceivedDm.new(job_application: self, recipient:).deliver_later
    end
  end

  def notify_applicant
    Hiring::JobApplicationMailer.with(job_application: self, message: status_message.presence).status_changed.deliver_later
    Hiring::ApplicationStatusChangedDm.new(job_application: self, message: status_message.presence).deliver_later
  end

  def job_accepts_applications
    return if job_post.nil?

    errors.add(:base, "This post isn't accepting applications here") unless job_post.accepts_applications? && job_post.active?
    errors.add(:base, "You can't apply to your own post") if profile && job_post.company.personal_owner_id == profile.user_id
  end
end
