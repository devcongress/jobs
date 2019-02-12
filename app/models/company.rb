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

class Company < ApplicationRecord
  # Associations
  has_many :jobs
  has_many :clients
  has_many :users, through: :clients

  # Validations
  validates :name,            presence: true
  validates :industry,        presence: true
  validates :website,         presence: true
  validates :description,     presence: true
  validates :email,           presence: true, uniqueness: true
  validates :phone,           presence: true
  validates :city,            presence: true
  validates :state_or_region, presence: true
  validates :post_code,       presence: true
  validates :country,         presence: true

  def to_param
    "#{id}-#{name.parameterize}"
  end
end
