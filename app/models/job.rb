# == Schema Information
#
# Table name: jobs
#
#  id            :bigint(8)        not null, primary key
#  role          :string
#  duration      :string
#  salary        :string
#  requirements  :string
#  qualification :string
#  perks         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  archived      :boolean          default(FALSE)
#  remote_ok     :boolean          default(TRUE), not null
#  company_id    :bigint(8)
#

class Job < ApplicationRecord
  belongs_to :company

  validates :company,       presence: true
  validates :duration,      presence: true
  validates :salary,        presence: true
  validates :requirements,  presence: true
  validates :qualification, presence: true
  validates :role,          presence: true

  def to_param
    "#{id}-#{role}-#{company}".parameterize
  end

  def title
    "#{role} at #{company.name}"
  end
end
