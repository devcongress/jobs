# frozen_string_literal: true

class Admin::ResendInviteInteraction < Plutonium::Resource::Interaction
  presents label: "Resend Invitation", icon: Phlex::TablerIcons::MailForward

  attribute :resource

  def execute
    unless resource.unverified?
      return failed("Can only resend invitations to unverified accounts")
    end

    RodauthApp.rodauth(:admin).verify_account_resend(login: resource.email)
    succeed(resource).with_message("Invitation resent to #{resource.email}")
  rescue ::Rodauth::InternalRequestError => e
    failed(e.message)
  end
end
