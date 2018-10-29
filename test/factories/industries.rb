FactoryBot.define do
  factory :industry do
    name { Faker::Company.industry }
  end
end
