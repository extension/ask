class ApplicationController < ActionController::Base
  protect_from_forgery
  layout "public"

  before_filter :store_location
  before_filter :personalize_location
  
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
  
  def require_exid
    if(!(current_user && current_user.has_exid?))
      return redirect_to(root_url)
    end
  end
  
  def record_not_found
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
  
  def personalize_location
    @personal = {}
    
    # get location and county from session, then IP
    if(!session[:location_and_county].blank? and !session[:location_and_county][:location_id].blank?)
      @personal[:location] = Location.find_by_id(session[:location_and_county][:location_id])
      if(!session[:location_and_county][:county_id].blank?)
        @personal[:county] = County.find_by_id(session[:location_and_county][:county_id])
      end
    end
    
    if(@personal[:location].blank?)
      if(location = Location.find_by_geoip(request.remote_ip))
        @personal[:location] = location
        session[:location_and_county] = {:location_id => location.id}
        if(county = County.find_by_geoip(request.remote_ip))
          @personal[:county] = county
          session[:location_and_county][:county_id] = county.id
        end
      end
    end
    return true
  end
  
end
