# == Schema Information
#
# Table name: jobs
#
#  id            :bigint(8)        not null, primary key
#  role          :string           not null
#  duration      :string
#  salary        :string           not null
#  requirements  :string           not null
#  qualification :string           not null
#  perks         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  archived      :boolean          default(FALSE)
#  remote_ok     :boolean          default(TRUE), not null
#  company_id    :bigint(8)        not null
#  city          :string           default(""), not null
#  country       :string           default(""), not null
#  apply_link    :text             default(""), not null
#  filled_at     :datetime
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
    "#{id}-#{role}-#{company.name}".parameterize
  end

  def title
    "#{role} at #{company.name}"
  end

  # `Job.active` is a version of `all` that returns
  # jobs that haven't been archived and are still within
  # the validity period since they were posted.
  def self.all_active
    Job.find_by_sql <<-SQL
      SELECT *
      FROM jobs
      WHERE NOT archived
            AND filled_at IS NULL
            AND tsrange(
              created_at,
              created_at + INTERVAL '#{self.validity_period}' DAY, '[]'
            ) @> now()::timestamp
            ORDER BY created_at DESC
    SQL
  end

  def self.validity_period
    (ENV['JOB_VALIDITY_PERIOD'] || 30).to_i.abs
  end

  def self.search(query)
    Job.find_by_sql [<<-SQL, query]
SELECT *
  FROM jobs
 WHERE NOT archived
       AND filled_at IS NULL
       AND tsrange(
        created_at,
        created_at + INTERVAL '#{self.validity_period}' DAY, '[]'
       ) @> now()::timestamp
       AND plainto_tsquery(?) @@ full_text_search
       ORDER BY created_at DESC
    SQL
  end
end
