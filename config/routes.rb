# allow the use of route file inclusions
# because this routes list is getting a little bit out of control.
class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

require 'sidekiq/web'
require 'admin_constraint'

Aae::Application.routes.draw do
  mount Sidekiq::Web => '/queues', :constraints => AdminConstraint.new

  # The priority is based upon order of creation:
  # first created -> highest priority.

  devise_for :users, :path => '/', :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }
  devise_for :authmaps, :controllers => { :omniauth_callbacks => "authmaps/omniauth_callbacks" } do
    get '/authmaps/auth/:provider' => 'authmaps/omniauth_callbacks#passthru'
  end

  # expert redirect routes
  match "/expert/home/locations/:id", to: redirect("/expert/locations/%{id}")
  match "/expert/home/users/locations/:id", to: redirect("/expert/locations/%{id}/experts")

  # config/routes/expert.rb
  draw :expert

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

  resources :locations

  # retired url
  match "users/retired" => "users#retired", :via => [:get]

  resources :users, :only => [:show]

  resources :groups do
    member do
      get 'ask'
      post 'create'
      get 'widget'
      get 'ask_widget'
      post 'ask_widget'
      post 'ask_ajax'
    end
  end


  # public search
  match "search/all" => "search#all", :via => [:get]

  # widgets for resolved questions
  match "widgets/front_porch" => "widgets#front_porch", :via => [:get]
  match "widgets/answered" => "widgets#answered", :via => [:get, :post]
  match "widgets/questions" => "widgets#questions", :via => [:get, :post]
  match "widgets/generate_widget_snippet" => "widgets#generate_widget_snippet", :via => [:post]
  match "widgets" => "widgets#index"


  # requires that if there is a parameter after the /ask, that it is in hexadecimal representation
  match "ask/:fingerprint" => "questions#submitter_view", :requirements => { :fingerprint => /[[:xdigit:]]+/ }, :via => [:get, :post], :as => 'submitter_view'
  match "questions/authorize_submitter" => "questions#authorize_submitter", :via => :post, :as => 'authorize_submitter'

  match "home/about" => "home#about", :via => :get
  match "home/accept_questions" => "home#accept_questions", :via => :get
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
  # route for js loaded widget
  match 'widget/js_widget/:fingerprint' => "widget#js_widget", :via => :get, :as => 'js_widget'
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
  match 'widget/ajax_counties/:location_id' => 'widget#ajax_counties', :via => :get

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
