# frozen_string_literal: true

class Admin::InviteInteraction < Plutonium::Resource::Interaction
  presents label: "Invite Admin", icon: Phlex::TablerIcons::Mail

  attribute :email
  attribute :role, default: :admin

  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :role, presence: true, inclusion: {in: Admin.roles.keys}

  input :role, as: :select, choices: Admin.roles.keys

  def execute
    account = nil
    Admin.transaction do
      RodauthApp.rodauth(:admin).create_account(login: email)
      account = Admin.find_by!(email: email)
      account.update!(role: role)
    end
    succeed(account).with_message("Invitation sent to #{email}")
  rescue ::Rodauth::InternalRequestError => e
    failed(email: e.message)
  end
end
