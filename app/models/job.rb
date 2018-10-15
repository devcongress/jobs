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
#  company_name  :string
#  contact_email :string
#  phone         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :integer
#  archived      :boolean          default(FALSE)
#  remote_ok     :boolean          default(TRUE), not null
#  company_id    :bigint(8)
#

class Job < ApplicationRecord
  belongs_to :user
  belongs_to :company

  validates :company_name,  presence: true
  validates :duration,      presence: true
  validates :salary,        presence: true
  validates :requirements,  presence: true
  validates :qualification, presence: true
  validates :company,       presence: true
  validates :contact_email, presence: true
  validates :user_id,       presence: true
  validates :role,          presence: true

  def to_param
    "#{id}-#{role}-#{company}".parameterize
  end

  def company
    @company || UnknownCompany.new(company_name, contact_email)
  end

  private

    class UnknownCompany
      attr_accessor :name, :email

      def initialize(name, email)
        @name = name
        @email = email
      end

      def marked_for_destruction?
        false
      end
    end
end
