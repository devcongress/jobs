# == Schema Information
#
# Table name: jobs
#
#  id            :bigint(8)        not null, primary key
#  role          :string           not null
#  duration      :string
#  salary        :string           not null
#  requirements  :string           not null
#  qualification :string           not null
#  perks         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  archived      :boolean          default(FALSE)
#  remote_ok     :boolean          default(TRUE), not null
#  company_id    :bigint(8)        not null
#  city          :string           default(""), not null
#  country       :string           default(""), not null
#

require 'test_helper'

class JobTest < ActiveSupport::TestCase

  setup do
    @subject = FactoryBot.create(:job, created_at: DateTime.now - 1.day)
  end

  test "associations" do
    must belong_to :company
  end

  test "validations" do
    must validate_presence_of :duration
    must validate_presence_of :salary
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
    # them is archived.
    FactoryBot.create(:job, archived: true)
    FactoryBot.create(:job, created_at: future_date)
    FactoryBot.create(:job, created_at: past_date)

    active_job_posts = Job.all_active

    assert_equal 1, active_job_posts.length
    assert_equal @subject.id, active_job_posts.first.id
  end
end
