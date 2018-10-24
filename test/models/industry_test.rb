require 'test_helper'

class IndustryTest < ActiveSupport::TestCase
  setup do
    @subject = FactoryBot.create(:industry)
  end

  test "validations" do
    must validate_presence_of   :name
    must validate_uniqueness_of :name
  end
end
