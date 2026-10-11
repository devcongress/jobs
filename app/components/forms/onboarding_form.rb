module Forms
  class OnboardingForm < BaseForm
    include DeveloperProfileFields

    def form_template
      div(class: "space-y-6") do
        section(data: {controller: "reveal"}) do
          choice :developer, "I'm a developer", "Create a profile with your skills, experience and projects."
          div(data: {reveal_target: "item"}, class: tokens("space-y-4", object.developer ? nil : "hidden")) { developer_profile_fields }
        end

        section(data: {controller: "reveal"}, class: "border-t border-[var(--pu-border-muted)] pt-6") do
          choice :hiring, "I'm hiring for a company", "Set up a company to post jobs and invite recruiters."
          div(data: {reveal_target: "item"}, class: tokens("space-y-4", object.hiring ? nil : "hidden")) do
            fields_wrapper do
              text :company_name, label: "Company name", required: true, span: true
              url :company_website, label: "Company website", span: true
              country :company_country, label: "Country"
              text :company_city, label: "City"
            end
          end
        end

        render_actions
      end
    end

    private

    def choice(name, label, hint)
      render field(name, label:, hint:).wrapped { |f| render f.toggle_tag(data: {action: "reveal#toggle"}) }
    end
  end
end
