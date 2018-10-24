# == Schema Information
#
# Table name: companies
#
#  id              :bigint(8)        not null, primary key
#  name            :text             not null
#  industry        :text             not null
#  logo            :text             default(""), not null
#  website         :text             default(""), not null
#  description     :text             not null
#  email           :text             not null
#  phone           :text             not null
#  city            :text             not null
#  state_or_region :text             not null
#  post_code       :text             not null
#  country         :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  setup do
    @subject = FactoryBot.create(:company)
  end

  test "associations" do
    must have_many     :jobs
    must have_db_index :email
  end

  test "validations" do
    must validate_presence_of :name
    must validate_presence_of :industry
    must validate_presence_of :description
    must validate_presence_of :email
    must validate_presence_of :phone
    must validate_presence_of :city
    must validate_presence_of :state_or_region
    must validate_presence_of :post_code
    must validate_presence_of :country

    must validate_uniqueness_of :email
  end
end
