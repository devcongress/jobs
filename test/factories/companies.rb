# == Schema Information
#
# Table name: companies
#
#  id              :bigint(8)        not null, primary key
#  name            :text             not null
#  industry        :text             not null
#  logo            :text             default(""), not null
#  website         :text             default(""), not null
#  description     :text             not null
#  email           :text             not null
#  phone           :text             not null
#  city            :text             not null
#  state_or_region :text             not null
#  post_code       :text             not null
#  country         :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  sequence(:company_email) { |n| "company_#{n}@example.com" }
  factory :company do
    name            { Faker::Company.name }
    industry        { Faker::Company.industry }
    logo            { Faker::Company.logo }
    website         { Faker::Internet.url }
    description     { Faker::Lorem.sentence }
    email           { generate(:company_email) }
    phone           { Faker::PhoneNumber.phone_number }
    city            { Faker::Address.city }
    state_or_region { Faker::Address.state }
    post_code       { Faker::Address.postcode }
    country         { Faker::Address.country }
  end
end
