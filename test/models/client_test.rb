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
