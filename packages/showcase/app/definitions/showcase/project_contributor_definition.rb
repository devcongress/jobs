module Showcase
  class ProjectContributorDefinition < Showcase::ResourceDefinition
    modal :centered

    action :confirm, interaction: Showcase::ConfirmContributionInteraction, category: :primary
    action :decline, interaction: Showcase::DeclineContributionInteraction, category: :danger,
      confirmation: "Decline this credit? You'll be removed from the project."

    field :profile, label: "Developer"
    field :confirmed_at, label: "Confirmed"
    input :handle, label: "Their handle", placeholder: "@handle",
      hint: "They'll get an email and show on the project once they confirm."
    input :role, placeholder: "e.g. Backend, design, maintainer"

    # Plain text in tables and public-page links on the record page: the
    # project or developer usually belongs to someone else, so a portal link
    # would lead nowhere.
    column :project, formatter: ->(project) { project&.title }
    column :profile, formatter: ->(profile) { profile && "#{profile.name} (@#{profile.handle})" }
    display(:project) { |field| PublicPageLink.new(record: field.value) }
    display(:profile) { |field| PublicPageLink.new(record: field.value) }
    column :status, as: :badge
    display :status, as: :badge
  end
end
