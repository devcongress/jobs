# Onboarding for a new user. Users pick what they are here for: a developer
# profile, a company (to hire), or both. At least one is required; the other
# can be added later from the dashboard.
class Onboarding
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :developer, :boolean, default: true
  attribute :first_name, :string
  attribute :other_names, :string
  attribute :handle, :string
  attribute :headline, :string
  attribute :city, :string
  attribute :country, :string
  attribute :github_url, :string
  attribute :visibility, :string, default: "everyone"

  attribute :hiring, :boolean, default: false
  attribute :company_name, :string
  attribute :company_website, :string
  attribute :company_country, :string
  attribute :company_city, :string

  validate :developer_or_hiring

  attr_reader :user, :profile, :company

  def initialize(user:, **attributes)
    @user = user
    super(**attributes)
    prefill_from_social_sign_in
    self.handle ||= suggested_handle
  end

  def save
    @profile = user.build_developer_profile(first_name:, other_names:, handle:, headline:, city:, country:, github_url:, visibility:) if developer
    @company = Company.new(name: company_name, website: company_website, country: company_country, city: company_city) if hiring

    return false unless valid? & records_valid?

    ActiveRecord::Base.transaction do
      profile&.save!
      if company
        company.save!
        company.company_users.create!(user:, role: :owner)
      end
    end
    true
  end

  private

  COMPANY_ERROR_ATTRIBUTES = {name: :company_name, website: :company_website, country: :company_country, city: :company_city}.freeze

  def developer_or_hiring
    errors.add(:base, "Choose a developer profile, a company, or both") unless developer || hiring
  end

  def records_valid?
    profile_valid = profile.nil? || profile.valid?
    company_valid = company.nil? || company.valid?

    profile&.errors&.each { |error| errors.import(error, attribute: error.attribute) }
    company&.errors&.each do |error|
      errors.import(error, attribute: COMPANY_ERROR_ATTRIBUTES.fetch(error.attribute, :base))
    end

    profile_valid && company_valid
  end

  # People who signed up with Google or GitHub get their name (and, from
  # GitHub, their username and profile link) filled in for them.
  def prefill_from_social_sign_in
    info = user.identities.order(:id).map(&:info).compact.reduce({}) { |merged, i| merged.merge(i.compact_blank) }
    return if info.empty?

    given, *others = info["name"].to_s.squish.split(" ")
    self.first_name ||= info["first_name"].presence || given
    self.other_names ||= info["last_name"].presence || others.join(" ").presence
    nickname = info["nickname"].to_s.downcase
    self.handle ||= nickname if nickname.match?(Developers::Profile::HANDLE_FORMAT)
    self.github_url ||= info.dig("urls", "GitHub")
  end

  def suggested_handle
    user.email.to_s.split("@").first.to_s.downcase.gsub(/[^a-z0-9_-]/, "-").squeeze("-").delete_prefix("-").delete_suffix("-").first(30)
  end
end
