DashboardPortal::Engine.routes.draw do
  root to: "dashboard#index"

  resource :notification_settings, only: %i[show update], path: "settings/notifications"
  get "settings/email", to: redirect("settings/notifications")
  resource :slack_connection, only: %i[destroy], path: "settings/slack"

  # register resources above.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end

# mount our app
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:user) do
    mount DashboardPortal::Engine, at: "/dashboard"
  end
end
