module Hiring
  # Presents one JobPost lifecycle method (publish!, renew!, ...) as an action.
  class JobPostTransitionInteraction < Hiring::ResourceInteraction
    class_attribute :transition, :success_message

    attribute :resource

    private

    def execute
      resource.public_send(transition)
      succeed(resource).with_message(success_message)
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
