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
  before_filter :set_yolo

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

  def set_yolo
    if(current_user)
      if(@yolo = current_user.yo_lo)
        @yolo.update_with_ip(request.remote_ip,current_user)
        session[:yolo_id] = @yolo.id
        return true
      end
    elsif(session[:yolo_id])
      if(@yolo = YoLo.find_by_id(session[:yolo_id]))
        @yolo.update_with_ip(request.remote_ip,current_user)
        return true
      end
    end
    @yolo = YoLo.create_from_ip(request.remote_ip,current_user)
    if(@yolo)
      session[:yolo_id] = @yolo.id
    end
  end

  def current_location
    if(!@yolo)
      set_yolo
    end
    @yolo.nil? ? nil : @yolo.location
  end

  def current_county
    if(!@yolo)
      set_yolo
    end
    @yolo.nil? ? nil : @yolo.county
  end

end
