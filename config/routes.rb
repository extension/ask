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
  resources :groups do
    member do
      get 'ask'
    end
  end
    
  namespace :expert do
    resources :questions
    resources :users, :except => [:destroy] do
      collection do
        get 'tags'
      end
    end
    resources :groups, :except => [:destroy] do
      collection do
        get 'questions_by_tag'
      end
    end
    
    match "groups/:id/members" => "groups#members", :via => :get, :as => 'group_members'
    match "groups/:id/profile" => "groups#profile", :via => [:get, :put], :as => 'group_profile'
    match "groups/:id/locations" => "groups#locations", :via => [:get, :put], :as => 'group_locations'
    match "groups/:id/assignment_options" => "groups#assignment_options", :via => [:get, :put, :post], :as => 'group_assignment_options'
    match "groups/:id/tags" => "groups#tags", :via => [:get, :put], :as => 'group_tags'
    match "groups/:id/widget" => "groups#widget", :via => [:get, :put, :post], :as => 'group_widget'
    match "groups/:id/history" => "groups#history", :via => [:get, :put], :as => 'group_history'
    match "settings/profile" => "settings#profile", :via => [:get, :put]
    match "settings/location" => "settings#location", :via => [:get, :put]
    match "settings/tags" => "settings#tags", :via => [:get, :put]
    match "settings/addlocation" => "settings#addlocation", :via => [:post]
    match "settings/removelocation" => "settings#removelocation", :via => [:post]
    match "settings/addcounty" => "settings#addcounty", :via => [:post]
    match "settings/removecounty" => "settings#removecounty", :via => [:post]
    match "settings/counties" => "settings#counties", :via => [:get]
    match "settings/show_counties" => "settings#show_counties", :via => [:get]
    match "settings/show_location" => "settings#show_location", :via => [:post]
    match "settings/editlocation" => "settings#editlocation", :via => [:get]
    match "settings/edit_location" => "settings#edit_location", :via => [:post]
    match "home" => "home#index"
    match "home/tags" => "home#tags"
    match "home/experts" => "home#experts"
    match "groups/add_tag" => "groups#add_tag", :via => [:post]
    match "groups/remove_tag" => "groups#remove_tag", :via => [:post]
    match "questions/add_tag" => "questions#add_tag", :via => [:post]
    match "questions/remove_tag" => "questions#remove_tag", :via => [:post]
    match "settings/add_tag" => "settings#add_tag", :via => [:post]
    match "settings/remove_tag" => "settings#remove_tag", :via => [:post]
  end
  
  match "home/private_page" => "home#private_page", :via => :get
  match "ask" => "home#ask"
  match "ajax/tags" => "ajax#tags", :via => [:get]
  
  
  
  ### Widget iFrame ###
  # route for existing bonnie_plants widget for continued operation.
  match 'widget/bonnie_plants/tracking/:fingerprint' => "widget#index", :via => :get
  # route for current url structure for accessing a widget
  match 'widget/tracking/:fingerprint' => "widget#index", :via => :get, :as => 'group_widget'
  # recognize widget/index as well
  match 'widget/index/:fingerprint' => "widget#index", :via => :get
  # Route for named/tracked widget w/ no location *unused is a catcher for /location and /location/county for
  # existing widgets, since we aren't using that in the URL anymore
  match 'widget/tracking/:fingerprint/*unused' => "widget#index", :via => :get
  # recognize widget/index as well with unused parameters
  match 'widget/index/:fingerprint/*unused' => "widget#index", :via => :get
  # Widget route for unnamed/untracked widgets
  match 'widget' => "widget#index", :via => :get
  # creation of question from widget
  match 'widget/create_from_widget' => 'widget#create_from_widget', :via => :post
  # get counties for widget
  match 'widget/get_counties/:location_id' => 'widget#get_counties', :via => :get
  
  
    
  root :to => 'home#index'
  
end
