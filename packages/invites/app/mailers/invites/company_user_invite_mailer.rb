# frozen_string_literal: true

module Invites
  class CompanyUserInviteMailer < ApplicationMailer
    prepend_view_path Invites::Engine.root.join("app/views")

    def invitation(invite)
      @invite = invite
      @invitation_url = company_user_invitation_url(token: invite.token)

      mail(
        to: invite.email,
        subject: invitation_subject,
        template_name: invitation_template_name
      )
    end

    private

    def invitation_subject
      "You're invited to join #{@invite.entity.to_label} on DevCongress Connect"
    end

    def invitation_template_name
      return "invitation" unless @invite.invitable_type.present?

      # e.g., "TenantProfile" -> "invitation_tenant_profile"
      template = "invitation_#{@invite.invitable_type.underscore}"
      template_exists?(template) ? template : "invitation"
    end

    def template_exists?(name)
      lookup_context.exists?(name, _prefixes, false, [], formats: [:html, :text])
    end
  end
end
