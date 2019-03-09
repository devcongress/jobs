# == Schema Information
#
# Table name: renewals
#
#  job_id     :bigint(8)        not null
#  user_id    :bigint(8)        not null
#  renewed_on :datetime         not null
#

require 'test_helper'

class RenewalTest < ActiveSupport::TestCase
  setup do
    @subject = FactoryBot.build(:renewal)
  end

  test "validations" do
    must validate_presence_of :job
    must validate_presence_of :renewed_on
  end

  test "associations" do
    must belong_to :job
  end
end
