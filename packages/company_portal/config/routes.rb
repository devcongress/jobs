CompanyPortal::Engine.routes.draw do
  root to: "dashboard#index"
  register_resource ::Company, singular: true
  register_resource ::CompanyUser
  register_resource ::Invites::CompanyUserInvite
  register_resource ::Hiring::JobPost
  register_resource ::Hiring::JobApplication

  # register resources above.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end

# mount our app
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:user) do
    mount CompanyPortal::Engine, at: "/company"
  end
end
