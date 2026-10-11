# frozen_string_literal: true

module Invites
  class CompanyUserInviteDefinition < Invites::ResourceDefinition
    action :resend, interaction: Invites::ResendInviteInteraction, collection_record_action: false
    action :cancel, interaction: Invites::CancelInviteInteraction, collection_record_action: false

    search do |scope, query|
      scope.where("email ILIKE ?", "%#{query}%")
    end

    # State scopes
    scope :pending
    scope :accepted
    scope :expired
    scope :cancelled

    # Role scopes
    scope :owner
    scope :recruiter
  end
end
