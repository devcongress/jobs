# == Schema Information
#
# Table name: clients
#
#  id         :bigint(8)        not null, primary key
#  company_id :bigint(8)        not null
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Client < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :user

  # Validations
  validates :company, presence: true
  validates :user,   presence: true
end
