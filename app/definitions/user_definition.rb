class UserDefinition < ::ResourceDefinition
  action :invite_user, interaction: User::InviteUserInteraction, category: :primary
end
