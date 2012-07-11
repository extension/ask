Aae::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  devise_for :users, :path => '/', :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }
  devise_for :authmaps, :controllers => { :omniauth_callbacks => "authmaps/omniauth_callbacks" } do 
    get '/authmaps/auth/:provider' => 'authmaps/omniauth_callbacks#passthru'
  end

  resources :questions
  resources :comments, :only => [:create, :update, :destroy, :show]
  resources :users
    
  namespace :expert do
    resources :questions
    resources :users
    resources :groups, :except => [:destroy]
    
    match "groups/:id/members" => "groups#members", :via => :get, :as => 'group_members'
    match "settings/profile" => "settings#profile", :via => [:get, :put]
    match "settings/location" => "settings#location", :via => [:get, :put]
    match "settings/addlocation" => "settings#addlocation", :via => [:post]
    match "settings/removelocation" => "settings#removelocation", :via => [:post]
    match "settings/addcounty" => "settings#addcounty", :via => [:post]
    match "settings/removecounty" => "settings#removecounty", :via => [:post]
    match "settings/counties" => "settings#counties", :via => [:get]
    match "home" => "home#index"
  end
  
  match "home/private_page" => "home#private_page", :via => :get
    
  root :to => 'home#index'
  
end
