module Hiring
  # Turns an applicant down, with an optional personal note in the email.
  # Also runs when a card is dropped on the board's Rejected column.
  class RejectApplicationInteraction < Hiring::ResourceInteraction
    presents label: "Reject", icon: Phlex::TablerIcons::UserX, description: "Let this applicant know you won't move forward"

    attribute :resource
    attribute :message, :string

    input :message, as: :text, label: "Message to the applicant",
      hint: "Optional. We always send a kind, standard note; anything here is added to it."

    private

    def execute
      resource.move_to!(:rejected, message:)
      succeed(resource).with_message("#{resource.profile.name} was rejected and notified.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
