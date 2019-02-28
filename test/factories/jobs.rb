# == Schema Information
#
# Table name: jobs
#
#  id               :bigint(8)        not null, primary key
#  role             :string           not null
#  duration         :string
#  salary           :numrange         not null
#  requirements     :string           not null
#  qualification    :string           not null
#  perks            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  archived         :boolean          default(FALSE)
#  remote_ok        :boolean          default(TRUE), not null
#  company_id       :bigint(8)        not null
#  city             :string           default(""), not null
#  country          :string           default(""), not null
#  apply_link       :text             default(""), not null
#  filled_at        :datetime
#  full_text_search :tsvector         not null
#

FactoryBot.define do
  sequence (:contact_email) { |n| "company#{n}@example.org" }

  factory :job do
    company

    qualification { Faker::Job.key_skill }
    requirements  { Faker::Lorem.paragraph(2) }
    role          { Faker::Job.title }
    salary_lower  { rand(0..1000) }
    salary_upper  { rand(2000..5000) }
    duration      { "#{rand(3)} - #{rand(5..10)} months" }
    archived      { false }
    remote_ok     { true }
    city          { Faker::Address.city }
    country       { Faker::Address.country }
    apply_link    { Faker::Internet.url }
    created_at    { 1.day.ago }
  end
end
