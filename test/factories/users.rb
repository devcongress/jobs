FactoryBot.define do
  sequence(:user_email) { |n| "user#{n}@example.org" }

  factory :user do
    email    { generate(:user_email) }
    password { Faker::Internet.password }
  end
end
