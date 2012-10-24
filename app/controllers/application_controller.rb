# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  helper_method :current_location
  helper_method :current_county

  protect_from_forgery
  layout "public"

  before_filter :store_redirect_url
  before_filter :set_session_location

  def store_redirect_url
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

  def set_session_location
    detected = {location_id: 0, county_id: 0}
    personal = {}
    # autodetect location
    location = Location.find_by_geoip(request.remote_ip)
    county = County.find_by_geoip(request.remote_ip)
    detected[:location_id] = location.id if location
    detected[:county_id] = county.id if county

    # check for session data
    if(session[:location_data].blank? or session[:location_data][:detected].blank? or session[:location_data][:detected][:location_id].blank?)
      personal = Marshal.load(Marshal.dump(detected))
      session[:location_data] = {detected: detected, personal: personal}
      return true
    end

    # we've got session location data - check for location mismatch
    if(location and session[:location_data][:detected][:location_id] != location.id)
      # location mismatch - override
      personal = Marshal.load(Marshal.dump(detected))
      session[:location_data] = {detected: detected, personal: detected}
      return true
    elsif(county and session[:location_data][:detected][:county_id] and session[:location_data][:detected][:county_id] != county.id)
      # county mismatch - override
      personal = Marshal.load(Marshal.dump(detected))
      session[:location_data] = {detected: detected, personal: personal}
      return true
    else
      # no override
    end
  end

  def current_location
    if(!@current_location)
      if(session[:location_data] and session[:location_data][:personal] and session[:location_data][:personal][:location_id])
        @current_location = Location.find_by_id(session[:location_data][:personal][:location_id])
      else
        @current_location = nil
      end
    end
    @current_location
  end

  def current_county
    if(!@current_county)
    if(session[:location_data] and session[:location_data][:personal] and session[:location_data][:personal][:county_id])
      county = County.find_by_id(session[:location_data][:personal][:county_id])
      # county validation check
      if(county and location = current_location and county.location_id == location.id)
        county
      else
        nil
      end
    else
      nil
    end
  end


end
