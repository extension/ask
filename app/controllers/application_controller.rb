class ApplicationController < ActionController::Base
  protect_from_forgery
  layout "expert"

  before_filter :store_location
  
  def store_location
    session[:user_return_to] = request.url unless (params[:controller] == "authmaps/omniauth_callbacks" || params[:controller] == "users/sessions")
  end
  
  # devise hook for the url to redirect to after a user has authenticated
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
  
  def stored_location_for(resource)
    if current_user && !params[:redirect_to].blank?
      return params[:redirect_to]
    end
    return nil
  end
end
