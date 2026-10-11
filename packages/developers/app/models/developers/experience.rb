# == Schema Information
#
# Table name: developers_experiences
#
#  id           :integer          not null, primary key
#  company_name :string           not null
#  description  :text
#  ended_on     :date
#  location     :string
#  started_on   :date             not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :integer
#  profile_id   :integer          not null
#
# Indexes
#
#  index_developers_experiences_on_company_id  (company_id)
#  index_developers_experiences_on_profile_id  (profile_id)
#
# Foreign Keys
#
#  company_id  (company_id => companies.id)
#  profile_id  (profile_id => developers_profiles.id)
#
require_relative "../developers"

class Developers::Experience < Developers::ResourceRecord
  # add concerns above.

  # add constants above.

  # add enums above.

  # add model configurations above.

  belongs_to :profile, class_name: "Developers::Profile"
  belongs_to :company, optional: true
  # add belongs_to associations above.

  # add has_one associations above.

  # add has_many associations above.

  # add attachments above.

  # add scopes above.

  validates :company_name, presence: true
  validates :title, presence: true
  validates :started_on, presence: true
  validates :ended_on, comparison: {greater_than_or_equal_to: :started_on}, allow_nil: true, if: :started_on
  # add validations above.

  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  def to_label
    "#{title} at #{company_name}"
  end

  def current?
    ended_on.nil?
  end

  # add methods above. add private methods below.
end
