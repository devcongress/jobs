module Hiring
  # Admin sends a job in review back to the company's drafts with a note.
  class DeclineJobPostInteraction < Hiring::ResourceInteraction
    presents label: "Decline", icon: Phlex::TablerIcons::ArrowBackUp, description: "Send it back to the company with a note"

    attribute :resource
    attribute :reason, :string

    input :reason, as: :text, hint: "Emailed to the company. Say what needs to change."

    validates :reason, presence: true

    private

    def execute
      resource.decline!(reason)
      succeed(resource).with_message("Declined. The company has been emailed.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
