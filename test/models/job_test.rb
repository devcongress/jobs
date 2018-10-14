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

require 'test_helper'

class JobTest < ActiveSupport::TestCase

  setup do
    @subject = Job.new
  end

  test "validations" do
    must validate_presence_of :company
    must validate_presence_of :duration
    must validate_presence_of :salary
    must validate_presence_of :requirements
    must validate_presence_of :qualification
    must validate_presence_of :contact_email
    must validate_presence_of :user_id
    must validate_presence_of :role
  end
end
