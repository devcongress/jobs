module Showcase
  class ProjectDefinition < Showcase::ResourceDefinition
    index_page_title "Projects"
    index_page_description "Things you've built. Credit the people you built them with."
    modal false

    field :body, as: :markdown, label: "Write-up"
    field :repo_url, as: :url, label: "Source code"
    field :demo_url, as: :url, label: "Live site or demo"
    field :started_on, label: "Started"
    field :ended_on, label: "Finished"
    field :visibility, label: "Who can see it"

    input :title, placeholder: "e.g. Momo payments SDK"
    input :summary, placeholder: "One line on what it is", hint: "Shown on cards and in search. 200 characters max."
    input :body, hint: "What it does, how you built it, what you learned. Markdown supported."
    field :skills, label: "Stack"
    input :skills, hint: "Languages, frameworks and tools it uses.", wrapper: {class: "col-span-full"}
    input :repo_url, placeholder: "https://github.com/you/project"
    input :demo_url, placeholder: "https://"
    input :ended_on, hint: "Leave blank if you're still working on it"
    input :visibility, as: :select,
      choices: [["Everyone who can see your profile", "everyone"], ["Signed-in members only", "members"], ["Hidden: only you", "hidden"]]

    display :body, wrapper: {class: "col-span-full"}
    display :summary, wrapper: {class: "col-span-full"}
    display :skills, wrapper: {class: "col-span-full"}
    column :visibility, as: :badge
    display :visibility, as: :badge

    search do |scope, query|
      scope.search(query)
    end

    sort :title
    sort :started_on
    default_sort :created_at, :desc

    form_layout do
      section :basics, :title, :summary, label: "Project"
      section :writeup, :body, label: "Write-up"
      section :stack, :skills, label: "Stack"
      section :links, :repo_url, :demo_url, label: "Links", columns: 2
      section :dates, :started_on, :ended_on, label: "Dates", columns: 2
      section :privacy, :visibility, label: "Privacy"
      ungrouped label: "Other"
    end

    display_layout do
      section :basics, :title, :summary, :skills, label: "Project"
      section :writeup, :body, label: "Write-up"
      section :details, :repo_url, :demo_url, :started_on, :ended_on, :visibility, label: "Details"
      ungrouped label: "Other"
    end
  end
end
