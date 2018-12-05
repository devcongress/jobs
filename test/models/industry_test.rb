# == Schema Information
#
# Table name: industries
#
#  id         :bigint(8)        not null, primary key
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

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
