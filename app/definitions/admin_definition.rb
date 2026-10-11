class AdminDefinition < ::ResourceDefinition
  action :invite, interaction: Admin::InviteInteraction, collection: true, category: :primary
  action :resend_invite, interaction: Admin::ResendInviteInteraction, record_action: true, category: :secondary
end
