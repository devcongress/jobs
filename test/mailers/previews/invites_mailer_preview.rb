# Company invite email. View at /rails/mailers/invites_mailer.
class InvitesMailerPreview < ActionMailer::Preview
  def company_invitation
    invite = Invites::CompanyUserInvite.last || Invites::CompanyUserInvite.new(
      company: Company.first!, invited_by: User.first!, email: "new-teammate@example.com", role: :recruiter,
      token: "preview-token", expires_at: 1.week.from_now
    )
    Invites::CompanyUserInviteMailer.invitation(invite)
  end
end
