module Hiring
  # A private note for the hiring team. Applicants never see these.
  class AddApplicationNoteInteraction < Hiring::ResourceInteraction
    presents label: "Add note", icon: Phlex::TablerIcons::Notes, description: "Only your team can see notes"

    attribute :resource
    attribute :body, :string

    input :body, as: :text, label: "Note", placeholder: "Interview feedback, next steps, anything the team should know"

    validates :body, presence: true, length: {maximum: 5_000}

    private

    def execute
      resource.add_note!(body, author: current_user)
      succeed(resource).with_message("Note added.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
