Rails.application.routes.draw do
  
  get '/help' => 'pages#help'
  get '/about' => 'pages#about'
  get '/privacy' => 'pages#privacy'
  
  resources :jobs
  root to: "pages#index"

end
