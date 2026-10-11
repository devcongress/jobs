# Project credit emails. View at /rails/mailers/showcase_mailer.
class ShowcaseMailerPreview < ActionMailer::Preview
  def contributor_invited
    Showcase::ContributorMailer.with(contributor: contributor(:pending)).invited
  end

  def contributor_confirmed
    Showcase::ContributorMailer.with(contributor: contributor(:confirmed)).confirmed
  end

  private

  def contributor(status)
    Showcase::ProjectContributor.where(status:).last || begin
      owner, profile = Developers::Profile.first(2)
      project = Showcase::Project.new(owner:, title: "Momo Pay SDK", summary: "Mobile money payments in one gem.", slug: "momo-pay-sdk")
      Showcase::ProjectContributor.new(project:, profile:, role: "Payments API", status:)
    end
  end
end
