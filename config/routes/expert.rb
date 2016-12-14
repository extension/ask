namespace :expert do

  resources :locations, :only => [:show, :index] do
    member do
      get :primary_groups
      post :add_primary_group
      post :remove_primary_group
      get :experts
      get :experts_email_csv
    end
  end


  resources :questions, :only => [:show, :edit, :update] do
    member do
      post 'assign'
      post 'assign_to_group'
      get 'assign_options'
      get 'group_assign_options'
      get  'answer'
      post 'answer'
      post 'assign_to_wrangler'
      post 'make_private'
      post 'make_public'
      post 'change_location'
      get  'reject'
      post 'reject'
      get  'reassign'
      post 'reassign'
      get  'wrangle'
      post 'wrangle'
      post 'reactivate'
      get  'close_out'
      post 'close_out'
      post 'activity_notification_prefs'
      get  'history'
      post 'restore_revision'
      get 'diff_with_previous'
      get 'edit_response'
      put 'update_response'
      get 'response_history'
      get 'diff_with_previous_response_revision'
      post 'restore_response_revision'
      post 'working_on_this'
      post 'feature'
    end
  end

  resources :users, :except => [:destroy] do
    member do
      get 'history'
    end
    collection do
      get 'tags'
      post 'save_listview_filter'
      post 'save_notification_prefs'
    end
  end

  resources :groups, :except => [:create, :destroy] do
    collection do
      get 'questions_by_tag'
      post 'new'
      get 'all'
    end
    member do
      get 'email_csv'
    end
  end

  resources :data, :only => [:index] do
    collection do
      get  :demographics
      get  :evaluations
      get  :questions
      get  :filter_questions
      post :filter_questions
      get  :filter_evaluations
      post :filter_evaluations
    end
  end

  namespace :data do
    match 'demographics/download', action: 'demographics_download'
    match 'questions/download', action: 'questions_download'
    match 'getfile', action: 'getfile', via: [:get,:post]
  end


  match "/" => "home#dashboard"
  match "reports", to: "reports#index", :via => [:get], :as => 'reports_home'
  match "reports/locations_and_groups", to: "reports#locations_and_groups", :via => [:get], :as => 'reports_locations_and_groups'
  match "reports/expert/:id", to: "reports#expert", :via => [:get], as: 'expert_report'
  match "reports/expert_list", to: "reports#expert_list", :via => [:get], :as => 'reports_expert_list'
  match "reports/expert_profile_list", to: "reports#expert_profile_list", :via => [:get], :as => 'reports_expert_profile_list'
  match "reports/question_list", to: "reports#question_list", :via => [:get], :as => 'reports_question_list'
  # match "reports/expert/:id/list", to: "reports#expert_list", :via => [:get], as: 'expert_list_report'
  match "reports/:action", to: "reports", :via => [:get]

  match "users/:id/answered" => "users#answered", :via => [:get], :as => 'user_answered'
  match "users/:id/watched" => "users#watched", :via => [:get], :as => 'user_watched'
  match "users/:id/rejected" => "users#rejected", :via => [:get], :as => 'user_rejected'
  match "users/:id/groups" => "users#groups", :via => [:get, :put, :post], :as => 'user_groups'
  match "users/:id/edit_attributes" => "users#edit_attributes", :via => [:get, :put], :as => 'edit_attributes'
  match "users/:id/submitted" => "users#submitted", :via => [:get], :as => 'user_submitted'
  match "users/:id/remove_group" => "users#remove_group", :via => [:post], :as => 'remove_group'
  match "groups/:id/members" => "groups#members", :via => :get, :as => 'group_members'
  match "groups/:id/profile" => "groups#profile", :via => [:get, :put], :as => 'group_profile'
  match "groups/:id/locations" => "groups#locations", :via => [:get, :put], :as => 'group_locations'
  match "groups/:id/assignment_options" => "groups#assignment_options", :via => [:get, :put, :post], :as => 'group_assignment_options'
  match "groups/:id/tags" => "groups#tags", :via => [:get, :put], :as => 'group_tags'
  match "groups/:id/widget" => "groups#widget", :via => [:get, :put, :post], :as => 'group_widget'
  match "groups/:id/history" => "groups#history", :via => [:get, :put], :as => 'group_history'
  match "groups/:id/about" => "groups#about", :via => [:get, :put], :as => 'about_group'
  match "groups/:id/answered" => "groups#answered", :via => [:get, :put], :as => 'group_answered'
  match "groups/:id/join" => "groups#join", :via => [:post], :as => 'group_join'
  match "groups/:id/leave" => "groups#leave", :via => [:post], :as => 'group_leave'
  match "groups/:id/lead" => "groups#lead", :via => [:post], :as => 'group_lead'
  match "groups/:id/unlead" => "groups#unlead", :via => [:post], :as => 'group_unlead'
  match "groups/create" => "groups#create", :via => [:post]

  # shortcut URL
  match "settings/profile" => "settings#profile", :via => [:get]
  match "settings/location" => "settings#profilelocation", :via => [:get]
  match "settings/tags" => "settings#tags", :via => [:get]
  match "settings/assignment" => "settings#assignment", :via => [:get]

  match "users/:id/settings/profile" => "settings#profile", :via => [:get, :put, :post], :as => 'profile_settings'
  match "users/:id/settings/location" => "settings#profilelocation", :via => [:get, :put, :post], :as => 'location_settings'
  match "users/:id/settings/tags" => "settings#tags", :via => [:get, :put, :post], :as => 'tags_settings'
  match "users/:id/settings/assignment" => "settings#assignment", :via => [:get, :put, :post], :as => 'assignment_settings'

  match "home" => "home#index"
  match "home/users/tags/:name" => "home#users_by_tag", :as => 'users_by_tag'
  match "home/groups/tags/:name" => "home#groups_by_tag", :as => 'groups_by_tag'
  match "home/questions/tags/:name" => "home#questions_by_tag", :as => 'questions_by_tag'
  match "home/groups/locations/:id" => "home#groups_by_location", :as => 'groups_by_location'
  match "home/questions/locations/:id" => "home#questions_by_location", :as => 'questions_by_location'
  match "home/users/counties/:id" => "home#users_by_county", :as => 'users_by_county'
  match "home/groups/counties/:id" => "home#groups_by_county", :as => 'groups_by_county'
  match "home/questions/counties/:id" => "home#questions_by_county", :as => 'questions_by_county'
  match "home/experts" => "home#experts"
  match "home/recent_activity" => "home#recent_activity"
  match "home/answered" => "home#answered"
  match "home/unanswered" => "home#unanswered"
  match "home/dashboard" => "home#dashboard"
  match "home/county/:id" => "home#county", :as => 'view_county'
  match 'home/get_counties/:location_id' => 'home#get_counties', :via => :get

  match "tags" => "tags#index"
  match "tags/edit_taggings" => "tags#edit_taggings", :as => 'edit_taggings'
  match "tags/edit/:name" => "tags#edit", :as => 'tag_edit'
  match "tags/delete" => "tags#delete", :as => 'delete'
  match "tags/delete_unused" => "tags#delete_unused", :as => 'delete_unused'
  match "tags/edit_confirmation" => "tags#edit_confirmation", :as => 'tag_edit_confirmation'
  match "tags/:name" => "tags#show", :as => 'show_tag'

  match "groups/add_tag" => "groups#add_tag", :via => [:post]
  match "groups/remove_tag" => "groups#remove_tag", :via => [:post]
  match "questions" => "questions#index"
  match "questions/add_tag" => "questions#add_tag", :via => [:post]
  match "questions/remove_tag" => "questions#remove_tag", :via => [:post]
  match "questions/add_history_comment" => "questions#add_history_comment", :via => [:post]
  match "questions/associate_with_group" => "questions#associate_with_group", :via => [:post]
  match "questions/activity_notificationprefs" => "questions#activity_notificationprefs", :via => [:post]
  match "settings/add_tag" => "settings#add_tag", :via => [:post]
  match "settings/remove_tag" => "settings#remove_tag", :via => [:post]
  match "search/all" => "search#all", :via => [:get]
  match "search/experts" => "search#experts", :via => [:get]
  match "search/by_name" => "search#by_name", :via => [:post]
  match "search/groups" => "search#groups", :via => [:get]
  match "search/questions" => "search#questions", :via => [:get]
  match "home/search" => "home#search", :via => [:get]

end # expert namespace
