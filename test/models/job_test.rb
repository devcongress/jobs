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
#

require 'test_helper'

class JobTest < ActiveSupport::TestCase
end
