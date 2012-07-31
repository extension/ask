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
    resources :groups, :except => [:destroy] do
      collection do
        get 'questions_by_tag'
      end
    end
    
    match "groups/:id/members" => "groups#members", :via => :get, :as => 'group_members'
    match "settings/profile" => "settings#profile", :via => [:get, :put]
    match "settings/location" => "settings#location", :via => [:get, :put]
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
  end
  
  match "home/private_page" => "home#private_page", :via => :get
  
  
  ### Widget iFrame ###
  # route for existing bonnie_plants widget for continued operation.
  match 'widget/bonnie_plants/tracking/:fingerprint' => "widget#index", :via => :get
  # Route for named/tracked widget w/ no location *unused is a catcher for /location and /location/county for
  # existing widgets, since we aren't using that in the URL anymore
  match 'widget/tracking/:fingerprint/*unused' => "widget#index", :via => :get, :as => 'widget_tracking'
  # recognize widget/index as well
  match 'widget/index/:fingerprint/*unused' => "widget#index", :via => :get
  # Widget route for unnamed/untracked widgets
  match 'widget' => "widget#index", :via => :get
  # creation of question from widget
  match 'widget/create_from_widget' => 'widget#create_from_widget', :via => :post
  # get counties for widget
  match 'widget/get_counties/:location_id' => 'widget#get_counties', :via => :get
  
  
    
  root :to => 'home#index'
  
end
