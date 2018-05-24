Rails.application.routes.draw do
  get '/' => 'pages/home'
  get '/help' => 'pages/help'
  get '/about' => 'pages/about'
  get '/privacy' => 'pages/privacy'
  resources :jobs
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end
