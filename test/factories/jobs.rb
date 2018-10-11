FactoryBot.define do
  sequence (:company_email) { |n| "company#{n}@example.org" }

  factory :job do
    user
    company       { Faker::Company.name }
    qualification { Faker::Job.key_skill }
    requirements  { Faker::Lorem.paragraphs(2) }
    role          { Faker::Job.title }
    contact_email { generate(:company_email) }
    salary        { "USD #{rand(1..2)} - #{rand(3..5)}" }
    duration      { "#{rand(3)} - #{rand(5..10)} months" }
    archived      { false }
  end
end
