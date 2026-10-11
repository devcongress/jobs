# frozen_string_literal: true

# == Schema Information
#
# Table name: company_user_invites
#
#  id              :integer          not null, primary key
#  accepted_at     :datetime
#  email           :string           not null
#  expires_at      :datetime
#  invitable_type  :string
#  invited_by_type :string           not null
#  metadata        :json
#  role            :integer          default("owner"), not null
#  state           :integer          default("pending"), not null
#  token           :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :integer          not null
#  invitable_id    :integer
#  invited_by_id   :integer          not null
#  user_id         :integer
#
# Indexes
#
#  index_company_user_invites_on_company_id            (company_id)
#  index_company_user_invites_on_entity_email_pending  (company_id,email) UNIQUE WHERE state = 0
#  index_company_user_invites_on_invitable             (invitable_type,invitable_id)
#  index_company_user_invites_on_invitable_pending     (invitable_type,invitable_id) UNIQUE WHERE state = 0 AND invitable_id IS NOT NULL
#  index_company_user_invites_on_invited_by            (invited_by_type,invited_by_id)
#  index_company_user_invites_on_token                 (token) UNIQUE
#  index_company_user_invites_on_user_id               (user_id)
#
# Foreign Keys
#
#  company_id  (company_id => companies.id)
#  user_id     (user_id => users.id)
#
module Invites
  class CompanyUserInvite < Invites::ResourceRecord
    include Plutonium::Invites::Concerns::InviteToken

    enum :role, CompanyUser.roles

    encrypts :token, deterministic: true

    belongs_to :company, class_name: "Company"
    belongs_to :invited_by, polymorphic: true
    belongs_to :user, optional: true
    belongs_to :invitable, polymorphic: true, optional: true

    validates :role, presence: true

    # Implement required methods from InviteToken concern

    def invitation_mailer
      Invites::CompanyUserInviteMailer
    end

    def enforce_domain
      nil
    end

    def create_membership_for(user)
      CompanyUser.create!(company: company, user: user, role: role)
    end

    # Alias for InviteToken concern compatibility (used by views/mailers
    # that read `@invite.entity.to_label`).
    alias_method :entity, :company
  end
end
