# == Schema Information
#
# Table name: renewals
#
#  job_id     :bigint(8)        not null
#  user_id    :bigint(8)        not null
#  renewed_on :datetime         not null
#

class Renewal < ApplicationRecord
  belongs_to :job

  validates_presence_of :job
  validates_presence_of :renewed_on
end
