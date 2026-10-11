module Hiring
  # An application's status as the hiring team sees it ("New" rather than
  # "Submitted"), so tables, pages and the board use the same stage names.
  class StageBadge < Plutonium::UI::Display::Components::Badge
    COLORS = {submitted: :info, reviewing: :primary, shortlisted: :warning, hired: :success, rejected: :danger, withdrawn: :neutral}.freeze

    def self.humanize(value)
      ::Hiring::JobApplication::STAGE_LABELS.fetch(value.to_s) { super }
    end

    def self.variant_for(value, colors: nil)
      super(value, colors: colors || COLORS)
    end
  end
end
