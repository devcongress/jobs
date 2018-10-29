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

FactoryBot.define do
  factory :client do
    company
    user
  end
end
