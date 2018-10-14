# == Schema Information
#
# Table name: jobs
#
#  id            :bigint(8)        not null, primary key
#  role          :string
#  duration      :string
#  salary        :string
#  requirements  :string
#  qualification :string
#  perks         :string
#  company       :string
#  contact_email :string
#  phone         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer
#  archived      :boolean          default(FALSE)
#  remote_ok     :boolean          default(TRUE), not null
#

FactoryBot.define do
  sequence (:company_email) { |n| "company#{n}@example.org" }

  factory :job do
    user
    company       { Faker::Company.name }
    qualification { Faker::Job.key_skill }
    requirements  { Faker::Lorem.paragraph(2) }
    role          { Faker::Job.title }
    contact_email { generate(:company_email) }
    salary        { "USD #{rand(1..2)} - #{rand(3..5)}" }
    duration      { "#{rand(3)} - #{rand(5..10)} months" }
    archived      { false }
  end
end
