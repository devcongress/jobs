module Forms
  class DeveloperProfileSetupForm < BaseForm
    include DeveloperProfileFields

    def form_template
      div(class: "space-y-6") do
        developer_profile_fields
        render_actions
      end
    end
  end
end
