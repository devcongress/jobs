# == Schema Information
#
# Table name: hiring_job_posts
#
#  id                   :integer          not null, primary key
#  accepts_applications :boolean          default(TRUE), not null
#  apply_url            :string
#  approved_at          :datetime
#  archived_at          :datetime
#  city                 :string
#  country              :string
#  description          :text             not null
#  duration             :string
#  employment_type      :integer          default("full_time"), not null
#  expires_at           :datetime
#  filled_at            :datetime
#  paid                 :boolean          default(TRUE), not null
#  pay_period           :integer          default("year"), not null
#  published_at         :datetime
#  remote_ok            :boolean          default(FALSE), not null
#  salary_currency      :string           default("USD"), not null
#  salary_max           :integer
#  salary_min           :integer
#  seniority            :integer
#  slack_message_ts     :string
#  slack_message_url    :string
#  slack_posted_status  :string
#  starts_on            :date
#  title                :string           not null
#  visibility           :integer          default("everyone"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_id           :integer          not null
#
# Indexes
#
#  index_hiring_job_posts_on_company_id                   (company_id)
#  index_hiring_job_posts_on_published_at_and_expires_at  (published_at,expires_at)
#
# Foreign Keys
#
#  company_id  (company_id => companies.id)
#
require_relative "../hiring"

# A job a company is hiring for. Lifecycle (from the old jobs app):
# draft -> published for VALIDITY_PERIOD -> expired (renewable), and it can be
# marked filled or archived at any point. Applications happen in the app,
# through an external link, or both.
#
# A company's first job is reviewed: until an admin approves one of its jobs
# the company isn't trusted, and publishing puts the job in review (hidden,
# admins emailed). Approval makes it live and trusts the company, so later
# jobs go live as soon as they're published.
class Hiring::JobPost < Hiring::ResourceRecord
  VALIDITY_PERIOD = ENV.fetch("JOB_VALIDITY_DAYS", 30).to_i.days

  # Changes to these show in the #jobs message (see Hiring::SlackJobPostSyncJob).
  SLACK_FIELDS = %w[
    published_at approved_at expires_at filled_at archived_at title description employment_type seniority
    salary_min salary_max salary_currency pay_period paid city country remote_ok duration starts_on
  ].freeze

  # What kind of post this is. Freelance posts are "gigs"; the board groups
  # types into kinds (see KINDS).
  enum :employment_type, {full_time: 0, part_time: 1, contract: 2, internship: 3, freelance: 4}
  TYPE_LABELS = {
    "full_time" => "Full time", "part_time" => "Part time", "contract" => "Contract",
    "freelance" => "Freelance / gig", "internship" => "Internship"
  }.freeze
  KINDS = {"jobs" => %w[full_time part_time contract], "gigs" => %w[freelance], "internships" => %w[internship]}.freeze
  # What the pay amount is per. "fixed" is a one-off budget for the whole piece of work.
  enum :pay_period, {year: 0, month: 1, day: 2, hour: 3, fixed: 4}, prefix: :paid_per
  PAY_PERIOD_LABELS = {"year" => "per year", "month" => "per month", "day" => "per day", "hour" => "per hour", "fixed" => "fixed budget"}.freeze
  enum :seniority, {junior: 0, mid: 1, senior: 2, lead: 3, principal: 4}
  # Who can see the job on the public site. Applying always needs an account.
  enum :visibility, {members: 1, everyone: 2}, prefix: :visible_to

  # /jobs/42-senior-rails-engineer (the id is what's looked up).
  dynamic_path_parameter :title

  belongs_to :company
  has_many :job_applications, class_name: "Hiring::JobApplication", dependent: :destroy

  scope :published, -> { where.not(published_at: nil) }
  scope :approved, -> { published.where.not(approved_at: nil) }
  scope :active, -> { approved.where(filled_at: nil, archived_at: nil).where("expires_at > ?", Time.current) }
  scope :drafts, -> { where(published_at: nil, archived_at: nil) }
  scope :pending_review, -> { published.where(approved_at: nil, filled_at: nil, archived_at: nil) }
  scope :newest, -> { order(published_at: :desc, created_at: :desc) }
  # Active jobs a viewer may see: public ones for guests, all for members.
  scope :visible_to, ->(user) { user ? active : active.visible_to_everyone }

  scope :of_kind, ->(kind) { where(employment_type: KINDS.fetch(kind.to_s)) }

  scope :search, ->(query) {
    term = "%#{sanitize_sql_like(query.to_s.strip.downcase)}%"
    joins(:company).where(
      "LOWER(hiring_job_posts.title) LIKE :t OR LOWER(hiring_job_posts.description) LIKE :t OR LOWER(companies.name) LIKE :t " \
      "OR LOWER(hiring_job_posts.city) LIKE :t OR LOWER(hiring_job_posts.country) LIKE :t", t: term
    )
  }

  validates :title, presence: true
  validates :description, presence: true
  validates :employment_type, presence: true
  validates :salary_currency, presence: true, **World.currency_validation
  validates :country, **World.country_validation
  validates :salary_min, :salary_max, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validates :salary_max, comparison: {greater_than_or_equal_to: :salary_min}, allow_nil: true, if: :salary_min
  validates :apply_url, **WebUrl.validation
  validates :duration, length: {maximum: 40}
  validate :has_a_way_to_apply
  validate :type_unchanged, on: :update

  normalizes :salary_currency, with: ->(currency) { currency.strip.upcase }

  after_commit :sync_to_slack, on: %i[create update], if: -> { Slack.posts_jobs? && saved_changes.keys.intersect?(SLACK_FIELDS) }
  # Deleting a live job closes its #jobs message. The record is gone by the
  # time a job runs, so the closed message is rendered now and sent after commit.
  before_destroy :render_slack_close, if: -> { Slack.posts_jobs? && slack_posted_status == "active" && slack_message_ts.present? }
  after_destroy_commit :close_slack_message, if: -> { @slack_close }

  # Only internships can be unpaid; permanent roles have no duration or start.
  before_validation do
    self.paid = true unless internship?
    self.duration = self.starts_on = nil unless time_bound?
  end

  def status
    if archived_at then :archived
    elsif filled_at then :filled
    elsif published_at.nil? then :draft
    elsif approved_at.nil? then :pending_review
    elsif expires_at&.past? then :expired
    else :active
    end
  end

  def active? = status == :active

  def visible_to?(user) = active? && (visible_to_everyone? || user.present?)

  def publishable? = status == :draft

  def pending_review? = status == :pending_review

  def renewable? = status == :expired

  def fillable? = %i[active expired].include?(status)

  # Goes live straight away for trusted companies; otherwise waits for review.
  def publish!
    if company.jobs_trusted?
      update!(published_at: Time.current, approved_at: Time.current, expires_at: VALIDITY_PERIOD.from_now)
    else
      update!(published_at: Time.current, approved_at: nil, expires_at: nil)
      Hiring::JobReviewMailer.with(job_post: self).review_requested.deliver_later
    end
  end

  # Admin approval: the job goes live for the full period and the company is
  # trusted from now on.
  def approve!
    transaction do
      update!(approved_at: Time.current, published_at: Time.current, expires_at: VALIDITY_PERIOD.from_now)
      company.update!(jobs_trusted_at: Time.current) unless company.jobs_trusted?
    end
    notify_company(:approved)
  end

  # Admin sends the job back to draft with a reason for the company.
  def decline!(reason)
    update!(published_at: nil, approved_at: nil, expires_at: nil)
    notify_company(:declined, reason:)
  end

  def renew!
    update!(expires_at: VALIDITY_PERIOD.from_now)
  end

  def mark_filled!
    update!(filled_at: Time.current)
  end

  def reopen!
    update!(filled_at: nil, expires_at: [expires_at, VALIDITY_PERIOD.from_now].compact.max)
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def location
    parts = [city, country].compact_blank.join(", ")
    remote_ok? ? [parts.presence, "Remote"].compact.join(" · ") : parts
  end

  # "job", "gig" or "internship", for wording that follows the post type.
  def kind_noun
    if freelance? then "gig"
    elsif internship? then "internship"
    else "job"
    end
  end

  def type_label = TYPE_LABELS.fetch(employment_type)

  # Gigs, contracts and internships have a length and a start; permanent roles don't.
  def time_bound? = !(full_time? || part_time?)

  # "60,000 – 90,000 USD per year", "500 USD fixed budget", "Unpaid".
  def pay
    return "Unpaid" unless paid?
    return if salary_min.nil? && salary_max.nil?

    amounts = [salary_min, salary_max].compact.uniq.map { |amount| ActiveSupport::NumberHelper.number_to_delimited(amount) }.join(" – ")
    "#{amounts} #{salary_currency} #{PAY_PERIOD_LABELS.fetch(pay_period)}"
  end
  alias_method :salary_range, :pay

  # "3 months · starts 1 Nov 2026"
  def timing
    return unless time_bound?

    [duration.presence, starts_on && "starts #{starts_on.strftime("%-d %b %Y")}"].compact.join(" · ").presence
  end

  def poster_name = company.display_name

  def to_label
    company.personal? ? "#{title} by #{poster_name}" : "#{title} at #{poster_name}"
  end

  private

  def sync_to_slack
    Hiring::SlackJobPostSyncJob.perform_later(self)
  end

  def render_slack_close
    message = Hiring::JobPostSlackMessage.new(self, closed_as: "archived")
    @slack_close = {ts: slack_message_ts, text: message.text, blocks: message.blocks}
  end

  def close_slack_message
    Hiring::SlackJobPostCloseJob.perform_later(**@slack_close)
  end

  def notify_company(email, **params)
    company.users.verified.find_each do |recipient|
      Hiring::JobReviewMailer.with(job_post: self, recipient:, **params).public_send(email).deliver_later
    end
  end

  # Applicants and the board rely on what kind of post this is, so it can't
  # change after creation. Post a new one instead.
  def type_unchanged
    errors.add(:employment_type, "can't be changed once the post is created") if employment_type_changed?
  end

  def has_a_way_to_apply
    return if accepts_applications? || apply_url.present?

    errors.add(:base, "Accept applications here, add an application link, or both")
  end
end
