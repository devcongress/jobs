Rails.application.routes.draw do
  get 'pages/home'
  get 'pages/help'
  get 'pages/about'
  get 'pages/privacy'
  resources :jobs
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/' => 'jobs#index'
  
end
