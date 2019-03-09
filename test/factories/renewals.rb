# == Schema Information
#
# Table name: renewals
#
#  job_id     :bigint(8)        not null
#  renewed_on :datetime         not null
#

FactoryBot.define do
  factory :renewal do
    job
    renewed_on { DateTime.now }
  end
end
