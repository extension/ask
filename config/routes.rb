Aae::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :questions
  root :to => 'home#index'
  
end
