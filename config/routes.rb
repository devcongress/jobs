# frozen_string_literal: true

Rails.application.routes.draw do
  get 'pages/terms'
  get 'pages/updates'
  root to: 'pages#index'

  get 'about'   => 'pages#about'
  get 'help'    => 'pages#help'
  get 'pricing' => 'pages#pricing'
  get 'privacy' => 'pages#privacy'
  get 'terms'   => 'pages#terms'
  get 'updates' => 'pages#updates'

  get 'profile' => 'profile#show'

  resources :companies
  resources :jobs do
    collection do
      get 'search'
    end

    member do
      post 'filled'
      post 'vacant'
      post 'renew'
    end
  end

  devise_for :users, skip: %i[sessions registrations passwords]

  devise_scope :user do
    # sessions
    get    'login',  to: 'users/sessions#new', as: :new_user_session
    post   'login',  to: 'users/sessions#login', as: :user_session
    get    'sign_in', to: 'users/sessions#create', as: :start_user_session
    delete 'logout', to: 'users/sessions#destroy', as: :destroy_user_session

    # registrations
    put    '/account',  to: 'users/registrations#update'
    delete '/account',  to: 'users/registrations#destroy'
    get '/register/complete', to: 'users/registrations#create', as: :complete_user_registration
    get    '/register', to: 'users/registrations#new', as: :new_user_registration
    post   '/register', to: 'users/registrations#register', as: :start_user_registration
    get    '/account',  to: 'users/registrations#edit',   as: :edit_user_registration
    patch  '/account',  to: 'users/registrations#update', as: :user_registration
    get    '/account/cancel', to: 'users/registrations#cancel', as: :cancel_user_registration

    # # passwords
    # get   'new-pass',  to: 'users/passwords#new',    as: :new_user_password
    # get   'edit-pass', to: 'users/passwords#edit',   as: :edit_user_password
    # patch 'edit-pass', to: 'users/passwords#update', as: :update_user_password
    # post  'new-pass',  to: 'users/passwords#create', as: :user_password
  end
end
