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

require 'test_helper'

class JobTest < ActiveSupport::TestCase

  setup do
    @subject = FactoryBot.create(:job)
  end

  test "associations" do
    must belong_to :company
  end

  test "validations" do
    must validate_presence_of :duration
    must validate_presence_of :requirements
    must validate_presence_of :qualification
    must validate_presence_of :role
  end

  test "all_active" do
    # Uses the default validity period. See the
    # self.validity_period in model for what the
    # current value is.
    past_date   = DateTime.now - (Job.validity_period + 1).days
    future_date = DateTime.now + (Job.validity_period + 1).days

    # These jobs are not matched since they fall
    # outside of the range of active job post. One of
    # them is archived and another is already filled.
    FactoryBot.create(:job, archived: true)
    FactoryBot.create(:job, created_at: future_date)
    FactoryBot.create(:job, created_at: past_date)
    FactoryBot.create(:job, filled_at: past_date)

    active_job_posts = Job.all_active

    assert_equal 1, active_job_posts.length
    assert_equal @subject.id, active_job_posts.first.id
  end

  test "search - role" do
    found = FactoryBot.create(:job, role: "full-stack developer")
    FactoryBot.create(:job) # not found

    jobs = Job.search("full stack developer")

    assert_equal 1, jobs.length

    match = jobs.first
    match.attributes.except("created_at", "updated_at", "full_text_search").each do |k, v|
      k = k.to_sym

      if v.nil?
        assert_nil found[k]
      else
        assert_equal v, found[k]
      end
    end
  end

  test "search - qualification" do
    found = FactoryBot.create(:job, qualification: "minimum 5 years experience")
    FactoryBot.create(:job) # not found

    jobs = Job.search("minimum experience")
    assert_equal 1, jobs.length

    match = jobs.first
    match.attributes.except("created_at", "updated_at", "full_text_search").each do |k, v|
      k = k.to_sym

      if v.nil?
        assert_nil found[k]
      else
        assert_equal v, found[k]
      end
    end
  end

  test "search - requirements" do
    found = FactoryBot.create(:job, requirements: "ruby proficiency\nopen source contributions\njavascript")
    FactoryBot.create(:job) # not found

    jobs = Job.search("proficient ruby")
    assert_equal 1, jobs.length

    match = jobs.first
    match.attributes.except("created_at", "updated_at", "full_text_search").each do |k, v|
      k = k.to_sym

      if v.nil?
        assert_nil found[k]
      else
        assert_equal v, found[k]
      end
    end
  end

  test "search - perks" do
    found = FactoryBot.create(:job, perks: "health insurance\n30-day holidays\nsummer vacation")
    FactoryBot.create(:job) # not found

    jobs = Job.search("insure")
    assert_equal 1, jobs.length

    match = jobs.first
    match.attributes.except("created_at", "updated_at", "full_text_search").each do |k, v|
      k = k.to_sym

      if v.nil?
        assert_nil found[k]
      else
        assert_equal v, found[k]
      end
    end
  end

  test "active?" do
    active_job = FactoryBot.create(:job)
    inactive_job = FactoryBot.create(:job, created_at: (Job.validity_period + 1).days.ago)

    assert active_job.active?
    refute inactive_job.active?
  end
end
