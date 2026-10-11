class CompanyDefinition < ::ResourceDefinition
  action :invite_user, interaction: Company::InviteUserInteraction, category: :secondary

  modal false
  submit_and_continue false

  field :description, as: :markdown
  field :website, as: :url

  input :slug, hint: "Used in your company's URLs"
  input :website, placeholder: "https://"
  input :description, hint: "What the company does and what it's like to work there. Markdown supported."
  input :country, as: :slim_select, choices: -> { World.country_names }, placeholder: "Choose a country"
  display :description, wrapper: {class: "col-span-full"}

  form_layout do
    section :company, :name, :slug, :website, label: "Company", columns: 2
    section :about, :description, label: "About"
    section :location, :country, :city, label: "Location", columns: 2
    ungrouped label: "Other"
  end

  display_layout do
    section :company, :name, :slug, :website, label: "Company"
    section :location, :country, :city, label: "Location"
    section :about, :description, label: "About"
    ungrouped label: "Other"
  end
end
