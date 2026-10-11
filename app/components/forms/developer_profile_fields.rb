module Forms
  # The profile fields asked for at onboarding and on /setup/developer.
  module DeveloperProfileFields
    VISIBILITY_CHOICES = {
      "everyone" => ["Public", "Anyone can find you in the directory, on your /@handle page and through search engines."],
      "members" => ["Members only", "Only people signed in to DevCongress Connect can see your profile."],
      "hidden" => ["Hidden", "Only you can see it until you change this."]
    }.freeze

    private

    def developer_profile_fields
      fields_wrapper do
        text :first_name, required: true
        text :other_names, hint: "Middle and last names"
        text :handle, span: true, required: true, hint: "Your public page will be at /@handle"
        text :headline, span: true, placeholder: "e.g. Backend engineer, Rails and Postgres",
          hint: "One line on what you do. It shows under your name in the directory and on your profile."
        country :country
        text :city
        profile_visibility
      end
    end

    def profile_visibility
      render field(:visibility, label: "Who can see your profile", hint: "You can change this any time from your profile settings.")
        .wrapped(class: span_class(true)) do |f|
          render f.collection_radio_buttons_tag(choices: VISIBILITY_CHOICES.transform_values(&:first), class: "grid gap-2") do |option|
            value = option.input_attributes[:checked_value]
            label(class: "flex cursor-pointer gap-3 rounded-lg border border-[var(--pu-border)] p-3 has-[:checked]:border-primary-500 has-[:checked]:bg-primary-50 dark:has-[:checked]:bg-primary-950") do
              render option.radio_button_tag(class: "pu-radio mt-0.5 shrink-0")
              span(class: "space-y-1") do
                span(class: "block text-sm font-medium text-[var(--pu-text)]") { VISIBILITY_CHOICES[value].first }
                span(class: "block text-xs text-[var(--pu-text-muted)]") { VISIBILITY_CHOICES[value].last }
              end
            end
          end
        end
    end
  end
end
