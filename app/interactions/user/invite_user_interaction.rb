# frozen_string_literal: true

class User::InviteUserInteraction < Plutonium::Resource::Interaction
  include Plutonium::Invites::Concerns::InviteUser

  presents label: "Invite User", icon: Phlex::TablerIcons::Mail

  attribute :role
  input :role, as: :select, choices: Invites::CompanyUserInvite.roles.keys.excluding("owner")

  private

  def entity
    current_scoped_entity
  end

  def invite_entity_attribute
    :company
  end

  def membership_class
    CompanyUser
  end

  # The concern defaults to Invites::UserInvite, which this app doesn't have.
  def invite_class
    Invites::CompanyUserInvite
  end
end
