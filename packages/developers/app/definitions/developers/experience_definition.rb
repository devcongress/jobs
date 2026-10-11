module Developers
  class ExperienceDefinition < Developers::ResourceDefinition
    index_page_title "Experience"
    index_page_description "The roles you've held, most recent first."
    modal :centered, size: :lg

    field :description, as: :markdown

    input :title, placeholder: "e.g. Senior Backend Engineer"
    input :company_name, label: "Company"
    input :location, placeholder: "e.g. Accra, Ghana or Remote"
    input :ended_on, hint: "Leave blank if this is your current role"
    field :started_on, label: "Started"
    field :ended_on, label: "Ended"
    column :company_name, label: "Company"
    display :company_name, label: "Company"
    display :description, wrapper: {class: "col-span-full"}

    sort :started_on
    default_sort :started_on, :desc

    form_layout do
      section :role, :title, :company_name, :location, columns: 2, label: "Role"
      section :dates, :started_on, :ended_on, columns: 2, label: "Dates"
      section :details, :description, label: "What you did"
      ungrouped label: "Other"
    end

    display_layout do
      section :role, :title, :company_name, :location, label: "Role"
      section :dates, :started_on, :ended_on, label: "Dates"
      section :details, :description, label: "What you did"
      ungrouped label: "Other"
    end
  end
end
