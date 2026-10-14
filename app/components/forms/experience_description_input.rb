module Forms
  class ExperienceDescriptionInput < Plutonium::UI::Component::Base
    CHECKLIST_ITEMS = [
      "I explained what I owned or was responsible for.",
      "I described what I built, improved, or solved.",
      "I included the result or impact, with numbers where possible.",
      "I added collaboration, leadership, or important constraints when relevant."
    ].freeze

    def initialize(field:)
      @field = field
    end

    def view_template
      div(class: "space-y-4") do
        render @field.markdown_tag
        checklist
      end
    end

    private

    def checklist
      fieldset(class: "experience-description-checklist rounded-[var(--pu-radius-lg)] border border-[var(--pu-border)] bg-[var(--pu-surface-alt)] p-4") do
        legend(class: "px-1 text-sm font-semibold text-[var(--pu-text)]") { "Description checklist" }
        p(class: "mb-3 text-xs text-[var(--pu-text-muted)]") do
          "Check each item when your description covers it. These checks are for your review and are not saved."
        end

        div(class: "grid gap-3 sm:grid-cols-2") do
          CHECKLIST_ITEMS.each_with_index do |item, index|
            label(class: "flex cursor-pointer items-start gap-2 text-sm text-[var(--pu-text)]") do
              # Deliberately omit `name`: these are private, temporary prompts
              # and can never become submitted Experience attributes.
              input(
                type: "checkbox",
                id: "experience-description-check-#{index}",
                class: "pu-checkbox mt-0.5 shrink-0"
              )
              span { item }
            end
          end
        end
      end
    end
  end
end
