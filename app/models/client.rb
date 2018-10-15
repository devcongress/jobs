class Client < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :user

  # Validations
  validates :company, presence: true
  validates :user,    presence: true
end
