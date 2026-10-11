module Hiring
  # The hiring team's overall rating of an applicant, 1 to 5.
  class RateApplicationInteraction < Hiring::ResourceInteraction
    presents label: "Rate", icon: Phlex::TablerIcons::Star, description: "Your team's rating of this applicant"

    attribute :resource
    attribute :rating, :integer

    input :rating, as: :select, include_blank: "No rating",
      choices: ::Hiring::JobApplication::RATINGS.to_a.reverse.map { |r| [("★" * r) + ("☆" * (5 - r)), r] }

    validates :rating, inclusion: {in: ::Hiring::JobApplication::RATINGS}, allow_nil: true

    private

    def execute
      resource.update!(rating:)
      succeed(resource).with_message(rating ? "Rated #{rating} out of 5." : "Rating cleared.")
    rescue ActiveRecord::RecordInvalid => e
      failed(e.record.errors)
    end
  end
end
