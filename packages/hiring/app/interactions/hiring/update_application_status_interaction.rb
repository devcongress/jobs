module Hiring
  # Company members move an applicant through their pipeline.
  class UpdateApplicationStatusInteraction < Hiring::ResourceInteraction
    STATUSES = %w[submitted reviewing shortlisted hired rejected].freeze

    presents label: "Move to stage", icon: Phlex::TablerIcons::Progress, description: "Move this applicant along your pipeline"

    attribute :resource
    attribute :status, :string
    attribute :message, :string

    input :status, label: "Stage", as: :select,
      choices: STATUSES.map { |s| [::Hiring::JobApplication::STAGE_LABELS.fetch(s), s] }
    input :message, as: :text, label: "Message to the applicant",
      hint: "Optional. Added to the email they get about the change. Moving back to New sends no email."

    validates :status, inclusion: {in: STATUSES}

    private

    def execute
      resource.move_to!(status, message:)
      succeed(resource).with_message("#{resource.profile.name} moved to #{resource.stage_label}.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
