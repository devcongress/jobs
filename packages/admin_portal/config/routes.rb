AdminPortal::Engine.routes.draw do
  root to: "dashboard#index"
  register_resource ::User
  register_resource ::Company
  register_resource ::Admin
  register_resource ::Skill
  register_resource ::Developers::Profile
  register_resource ::Hiring::JobPost
  register_resource ::Hiring::JobApplication
  register_resource ::Showcase::Project
  register_resource ::Showcase::ProjectContributor
  register_resource ::Network::Follow
  register_resource ::Network::Endorsement

  # register resources above.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end

# mount our app
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:admin) do
    mount AdminPortal::Engine, at: "/admin"
  end
end
