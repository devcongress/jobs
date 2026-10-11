module Developers
  class ProfileSkillDefinition < Developers::ResourceDefinition
    index_page_title "Skills"
    index_page_description "Languages, frameworks and tools you work with."
    modal :centered

    input :skill, wrapper: {class: "col-span-full"}
    input :years, hint: "Years of experience with this skill"

    field :endorsements_count, label: "Endorsements"

    sort :years
    sort :endorsements_count
    default_sort { |scope| scope.joins(:skill).order("skills.name") }

    form_layout do
      section :skill, :skill, :level, :years, columns: 2
    end
  end
end
