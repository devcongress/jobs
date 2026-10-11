module Hiring
  # Moves several applicants at once, e.g. rejecting everyone left once a role is filled.
  class MoveApplicationsInteraction < Hiring::ResourceInteraction
    presents label: "Move to stage", icon: Phlex::TablerIcons::Progress, description: "Move the selected applicants"

    attribute :resources
    attribute :status, :string
    attribute :message, :string

    input :status, label: "Stage", as: :select,
      choices: UpdateApplicationStatusInteraction::STATUSES.map { |s| [::Hiring::JobApplication::STAGE_LABELS.fetch(s), s] }
    input :message, as: :text, label: "Message to the applicants",
      hint: "Optional. Added to the email each applicant gets."

    validates :status, inclusion: {in: UpdateApplicationStatusInteraction::STATUSES}

    private

    def execute
      moved = ::Hiring::JobApplication.transaction do
        resources.reject { |a| a.status == status }.each { |a| a.move_to!(status, message:) }
      end
      label = ::Hiring::JobApplication::STAGE_LABELS.fetch(status)
      succeed(resources).with_message("#{moved.size} #{"applicant".pluralize(moved.size)} moved to #{label}.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
