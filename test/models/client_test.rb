# == Schema Information
#
# Table name: clients
#
#  id         :bigint(8)        not null, primary key
#  company_id :bigint(8)        not null
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  setup do
    @subject = FactoryBot.build(:client)
  end

  test "validations" do
    must validate_presence_of :user
    must validate_presence_of :company
  end

  test "associations" do
    must belong_to :user
    must belong_to :company
  end
end
