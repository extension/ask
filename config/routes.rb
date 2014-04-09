Aae::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  devise_for :users, :path => '/', :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }
  devise_for :authmaps, :controllers => { :omniauth_callbacks => "authmaps/omniauth_callbacks" } do
    get '/authmaps/auth/:provider' => 'authmaps/omniauth_callbacks#passthru'
  end

  resources :questions do
    collection do
      post 'account_review_request'
    end
  end

  resources :responses, :only => [:create] do
    member do
      post 'remove_image'
    end
  end

  resources :comments, :only => [:create, :update, :destroy, :show, :edit] do
    collection do
      get 'cancel_edit'
      get 'cancel_reply'
      get 'reply'
      post 'reply'
    end
  end

  # retired url
  match "users/retired" => "users#retired", :via => [:get]

  resources :users do
    member do
      post 'comment_notification_subscription'
    end
  end

  resources :groups do
    member do
      get 'ask'
      post 'ask'
      get 'widget'
    end
  end

  namespace :expert do
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
    match "reports", to: "reports#home_mockup", :via => [:get], :as => 'reports_home'
    match "reports/locations_and_groups", to: "reports#locations_and_groups", :via => [:get], :as => 'reports_locations_and_groups'
    match "reports/expert/:id", to: "reports#expert", :via => [:get], as: 'expert_report'
    match "reports/expert_list", to: "reports#expert_list", :via => [:get], :as => 'reports_expert_list'
    match "reports/question_list", to: "reports#question_list", :via => [:get], :as => 'reports_question_list'
    # match "reports/expert/:id/list", to: "reports#expert_list", :via => [:get], as: 'expert_list_report'
    match "reports/:action", to: "reports", :via => [:get]

    match "users/:id/answered" => "users#answered", :via => [:get], :as => 'user_answered'
    match "users/:id/watched" => "users#watched", :via => [:get], :as => 'user_watched'
    match "users/:id/rejected" => "users#rejected", :via => [:get], :as => 'user_rejected'
    match "users/:id/groups" => "users#groups", :via => [:get, :put, :post], :as => 'user_groups'
    match "users/:id/edit_attributes" => "users#edit_attributes", :via => [:get, :put], :as => 'edit_attributes'
    match "users/:id/submitted" => "users#submitted", :via => [:get], :as => 'user_submitted'
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
    match "settings/profile" => "settings#profile", :via => [:get, :put]
    match "settings/location" => "settings#location", :via => [:get, :put]
    match "settings/tags" => "settings#tags", :via => [:get, :put]
    match "settings/assignment" => "settings#assignment", :via => [:get, :put]
    match "home" => "home#index"
    match "home/tags/:name" => "home#tags", :as => 'home_tags'
    match "home/users/tags/:name" => "home#users_by_tag", :as => 'users_by_tag'
    match "home/groups/tags/:name" => "home#groups_by_tag", :as => 'groups_by_tag'
    match "home/questions/tags/:name" => "home#questions_by_tag", :as => 'questions_by_tag'
    match "home/users/locations/:id" => "home#users_by_location", :as => 'users_by_location'
    match "home/users/locations/:id/email_list" => "home#users_by_location_email_csv", :as => 'users_by_location_email_csv'
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
    match "home/managetags" => "home#managetags"
    match "home/locations/:id" => "home#locations", :as => 'view_location'
    match "home/county/:id" => "home#county", :as => 'view_county'
    match 'home/get_counties/:location_id' => 'home#get_counties', :via => :get
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
  end

  # public search
  match "search/all" => "search#all", :via => [:get]

  # widgets for resolved questions
  match "widgets/front_porch" => "widgets#front_porch", :via => [:get]
  match "widgets/answered" => "widgets#answered", :via => [:get]

  # requires that if there is a parameter after the /ask, that it is in hexadecimal representation
  match "ask/:fingerprint" => "questions#submitter_view", :requirements => { :fingerprint => /[[:xdigit:]]+/ }, :via => [:get, :post], :as => 'submitter_view'
  match "questions/authorize_submitter" => "questions#authorize_submitter", :via => :post, :as => 'authorize_submitter'

  match "home/about" => "home#about", :via => :get
  match "home/unanswered" => "home#unanswered", :via => :get
  match "home/change_yolo" => "home#change_yolo", :via => [:post]
  match "home/locations/:id" => "home#locations", :as => 'view_location'
  match "home/county/:id" => "home#county", :as => 'view_county'
  match "home/private_page" => "home#private_page", :via => :get
  match "home/county_options_list/:location_id" => "home#county_options_list", :via => :get
  match "settings/profile" => "settings#profile", :via => [:get, :put], :as => 'nonexid_profile_edit'

  match "home/questions/tags/:name" => "home#questions_by_tag", :as => 'questions_by_tag'

  match "ask" => "groups#ask", :id => "38" #id for QW group

  match "ajax/tags" => "ajax#tags", :via => [:get]
  match "ajax/groups" => "ajax#groups", :via => [:get]
  match "ajax/experts" => "ajax#experts", :via => [:get]
  match "ajax/counties" => "ajax#counties", :via => [:get]
  match "ajax/show_location" => "ajax#show_location", :via => [:get, :post]
  match "ajax/edit_location" => "ajax#edit_location", :via => [:get, :post]
  match "ajax/add_county" => "ajax#add_county", :via => [:post]
  match "ajax/add_location" => "ajax#add_location", :via => [:post]
  match "ajax/remove_county" => "ajax#remove_county", :via => [:post]
  match "ajax/remove_location" => "ajax#remove_location", :via => [:post]
  match "ajax/group_by_category_id" => "ajax#group_by_category_id", :via => [:get]

  # wildcard
  match "ajax/:action", to: "ajax", :via => [:get, :post]

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

  # webmail routes
  scope "webmail" do
    match "/:mailer_cache_id/logo" => "webmail#logo", :as => 'webmail_logo'
    match "/view/:hashvalue" => "webmail#view", :as => 'webmail_view'
  end

  match "webmail/examples", to: "webmail/examples#index", :via => [:get], :as => 'webmail_index'
  # webmail example routing
  namespace "webmail" do
    namespace "examples" do
      match "/:action"
    end
  end

  # evaluation
  match "evaluation/answer_evaluation", to: "evaluation#answer_evaluation", via: [:post], as: 'answer_evaluation'
  match "evaluation/answer_demographic", to: "evaluation#answer_demographic", via: [:post], as: 'answer_demographic'
  match "evaluation/question/:id", to: "evaluation#question", via: [:get], as: 'evaluation_form'
  match "evaluation/view/:fingerprint" => "evaluation#view", :requirements => { :fingerprint => /[[:xdigit:]]+/ }, :via => [:get], :as => 'view_evaluation'
  match "evaluation/authorize" => "evaluation#authorize", via: [:post], :as => 'authorize_evaluation'
  match "evaluation/example" => "evaluation#example", via: [:get], :as => 'example_evaluation'
  match "evaluation/thanks" => "evaluation#thanks", via: [:get], :as => 'evaluation_thanks'

  # feeds
  match "feeds/answered_questions", :via => :get, :defaults => { :format => 'xml' }

  # wildcard
  match "evaluation/:action", to: "evaluation", :via => [:get, :post]

  # reports
  match "reports/expert/:id", to: "reports#expert", :via => [:get], as: 'expert_report'
  match "reports/expert/:id/list", to: "reports#expert_list", :via => [:get], as: 'expert_list_report'
  match "reports/:action", to: "reports", :via => [:get]


  # wildcard
  match "debug/:action", to: "debug", :via => [:get]

  # json data enpoints for tokeninput
  controller :selectdata do
    simple_named_route 'groups', via: [:get]
    simple_named_route 'locations', via: [:get]
    simple_named_route 'counties', via: [:get]
    simple_named_route 'tags', via: [:get]
  end


  root :to => 'home#index'

end
