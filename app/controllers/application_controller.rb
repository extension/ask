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
  
  def questions_based_on_pref_filter(list_view, filter_pref)
    condition_array = Array.new
    if filter_pref
      !filter_pref.setting[:question_filter][:locations].blank? ? @location_pref = filter_pref.setting[:question_filter][:locations][0].to_i : @location_pref = nil
      filter_pref.setting[:question_filter][:counties].present? ? @county_pref = filter_pref.setting[:question_filter][:counties][0].to_i : @county_pref = nil
      filter_pref.setting[:question_filter][:groups].present? ? @group_pref = filter_pref.setting[:question_filter][:groups][0].to_i : @group_pref = nil
      filter_pref.setting[:question_filter][:tags].present? ? @tag_pref = filter_pref.setting[:question_filter][:tags][0].to_i : @tag_pref = nil 
    end
    
    if @location_pref.present?
      condition_array << "questions.location_id = #{@location_pref.to_i}"
    end
    
    if @county_pref.present?
      condition_array << "questions.county_id = #{@county_pref.to_i}"
    end
    
    if @group_pref.present?
      condition_array << "questions.assigned_group_id = #{@group_pref.to_i}"
    end
    
    condition_array.empty? ? condition_string = nil : condition_string = condition_array.join(' AND ')
    
    if list_view.present? 
      if list_view == 'resolved'
        question_order = "questions.resolved_at DESC"
      elsif list_view == 'incoming'
        question_order = "questions.created_at DESC"
      end
    else
      question_order = "questions.created_at DESC"
    end    
      
    if @tag_pref.present?
      return Question.tagged_with(@tag_pref.to_i).where(condition_string).order(question_order).limit(20)
    else
      return Question.where(condition_string).order(question_order).limit(20)
    end
  end

end
