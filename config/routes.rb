Aae::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  devise_for :users, :path => '/', :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }
  devise_for :authmaps, :controllers => { :omniauth_callbacks => "authmaps/omniauth_callbacks" } do 
    get '/authmaps/auth/:provider' => 'authmaps/omniauth_callbacks#passthru'
  end

  resources :questions
  resources :users
  
  namespace :expert do
    resources :questions
    resources :users
    
    match "settings/profile" => "settings#profile", :via => [:get, :put]
    match "home" => "home#index", :via => [:get, :put]
  end
    
  root :to => 'home#index'
  
end
