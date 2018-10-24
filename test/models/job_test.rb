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

require 'test_helper'

class JobTest < ActiveSupport::TestCase

  setup do
    @subject = FactoryBot.build(:job)
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
end
