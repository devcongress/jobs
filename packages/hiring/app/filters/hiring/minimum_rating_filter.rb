module Hiring
  # "Rated at least N stars" on the applicants list.
  class MinimumRatingFilter < Plutonium::Query::Filter
    def apply(scope, value: nil)
      return scope if value.blank?

      scope.where(rating: value.to_i..)
    end

    def customize_inputs
      input :value, as: :select, include_blank: "Any rating",
        choices: [5, 4, 3, 2, 1].map { |r| [(r == 5) ? "★★★★★" : "#{"★" * r} or more", r] }
    end
  end
end
