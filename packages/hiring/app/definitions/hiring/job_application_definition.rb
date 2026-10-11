module Hiring
  class JobApplicationDefinition < Hiring::ResourceDefinition
    modal :centered

    action :update_status, interaction: Hiring::UpdateApplicationStatusInteraction, category: :primary
    action :withdraw, interaction: Hiring::WithdrawApplicationInteraction, category: :danger,
      confirmation: "Withdraw this application?"

    field :job_post, label: "Job"
    field :profile, label: "Applicant"
    field :created_at, label: "Applied"
    column :created_at, as: :date, label: "Applied"
    display :status, as: :badge
    column :status, as: :badge
    display :cover_note, wrapper: {class: "col-span-full"}

    default_sort :created_at, :desc
  end
end
