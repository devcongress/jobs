# == Schema Information
#
# Table name: industries
#
#  id         :bigint(8)        not null, primary key
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :industry do
    name { Faker::Company.industry }
  end
end
