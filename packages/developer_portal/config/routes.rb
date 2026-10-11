DeveloperPortal::Engine.routes.draw do
  root to: "dashboard#index"
  # Nested routes are declared explicitly: a profile also has followers,
  # following and endorsers, and those must not get portal routes.
  register_resource ::Developers::Profile, singular: true, associations: %i[experiences profile_skills]
  register_resource ::Developers::Experience
  register_resource ::Developers::ProfileSkill, associations: []
  register_resource ::Hiring::JobPost, associations: []
  register_resource ::Hiring::JobApplication, associations: []
  register_resource ::Showcase::Project, associations: %i[contributors]
  register_resource ::Showcase::ProjectContributor

  # Followers, following, connections and suggestions.
  get "network", to: "network#index", as: :network

  # register resources above.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end

# mount our app
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:user) do
    mount DeveloperPortal::Engine, at: "/developer"
  end
end
