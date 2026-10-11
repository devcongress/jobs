module Hiring
  class WithdrawApplicationInteraction < Hiring::ResourceInteraction
    presents label: "Withdraw", icon: Phlex::TablerIcons::ArrowBackUp, description: "Withdraw this application"

    attribute :resource

    private

    def execute
      resource.withdraw!
      succeed(resource).with_message("Application withdrawn.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
