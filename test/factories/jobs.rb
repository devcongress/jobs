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
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  archived      :boolean          default(FALSE)
#  remote_ok     :boolean          default(TRUE), not null
#  company_id    :bigint(8)
#

FactoryBot.define do
  sequence (:contact_email) { |n| "company#{n}@example.org" }

  factory :job do
    company { create(:company) }

    qualification { Faker::Job.key_skill }
    requirements  { Faker::Lorem.paragraph(2) }
    role          { Faker::Job.title }
    salary        { "USD #{rand(1..2)} - #{rand(3..5)}" }
    duration      { "#{rand(3)} - #{rand(5..10)} months" }
    archived      { false }
    remote_ok     { true }
  end
end
