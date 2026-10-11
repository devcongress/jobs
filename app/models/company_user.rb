# == Schema Information
#
# Table name: company_users
#
#  id         :integer          not null, primary key
#  role       :integer          default("owner"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_company_users_on_company_id              (company_id)
#  index_company_users_on_company_id_and_user_id  (company_id,user_id) UNIQUE
#  index_company_users_on_user_id                 (user_id)
#
# Foreign Keys
#
#  company_id  (company_id => companies.id)
#  user_id     (user_id => users.id)
#
class CompanyUser < ::ResourceRecord
  # add concerns above.

  # add constants above.
  enum :role, owner: 0, recruiter: 1

  # add enums above.

  # add model configurations above.

  belongs_to :company
  belongs_to :user
  # add belongs_to associations above.

  # add has_one associations above.

  # add has_many associations above.

  # add attachments above.

  # add scopes above.

  validates :role, presence: true
  validates :user, uniqueness: {scope: :company_id, message: "is already a member of this company"}
  # add validations above.

  # add callbacks above.

  # add delegations above.

  # add misc attribute macros above.

  # add methods above. add private methods below.
end
