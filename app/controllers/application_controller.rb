# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  helper_method :current_location
  helper_method :current_county
  before_filter :set_time_zone_from_user, :set_last_active_at_for_user

  protect_from_forgery
  layout "public"

  before_filter :store_redirect_url
  before_filter :set_yolo
  
  # identify the culprit of the papertrail revisions, it's either someone logged in that creates or edits a question or someone from the public who has a user record created and associated with them
  def user_for_paper_trail
    current_user.present? ? current_user.id : session[:submitter_id]
  end
  
  # additional tracking information for papertrail
  def info_for_paper_trail
    { :ip_address => request.remote_ip }
  end
  
  # turn off paper trail on the create action. we have it configured for updates only, but somehow papertrail is detecting an update on body and title (thus generating a new revision) on create
  def paper_trail_enabled_for_controller
    params[:action] != 'create' && params[:action] != 'ask' && params[:action] != 'answer'
  end

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

  def set_time_zone_from_user
    if(current_user)
      Time.zone = current_user.time_zone
    else
      Time.zone = Settings.default_display_timezone
    end
    true
  end
  
  def set_last_active_at_for_user
    if current_user
      if current_user.last_active_at != Date.today 
        current_user.update_attribute(:last_active_at, Date.today)
      end
    end
    return true
  end

  def questions_based_on_pref_filter(filter_pref)
    condition_array = Array.new
    if filter_pref
      filter_pref.setting[:question_filter][:locations].present? ? @location_pref = filter_pref.setting[:question_filter][:locations][0].to_i : @location_pref = nil
      filter_pref.setting[:question_filter][:counties].present? ? @county_pref = filter_pref.setting[:question_filter][:counties][0].to_i : @county_pref = nil
      filter_pref.setting[:question_filter][:groups].present? ? @group_pref = filter_pref.setting[:question_filter][:groups][0].to_i : @group_pref = nil
      filter_pref.setting[:question_filter][:tags].present? ? @tag_pref = filter_pref.setting[:question_filter][:tags][0].to_i : @tag_pref = nil 
    end
    
    filter_description_array = Array.new
    
    if params[:override].present?
      @location_pref = params[:location_id]
      @county_pref = params[:county_id]
      @group_pref = params[:group_id]
      @tag_pref = params[:tag_id]
    end
    
    if params[:status].present?
      @status = params[:status]
      if @status == "answered"
        filter_description_array << "Answered"
      elsif @status == "unanswered"
        filter_description_array << "Needs an Answer"
      else
        # all questions
      end
    end

    if @county_pref.present?
      condition_array << "questions.county_id = #{@county_pref.to_i}"
      @county = County.find_by_id(@county_pref)
      filter_description_array << "#{@county.name}"
    end
    
    if @location_pref.present?
      condition_array << "questions.location_id = #{@location_pref.to_i}"
      @location = Location.find_by_id(@location_pref)
      filter_description_array << "#{@location.name}"
    end
    
    if @group_pref.present?
      condition_array << "questions.assigned_group_id = #{@group_pref.to_i}"
      @group = Group.find_by_id(@group_pref)
      filter_description_array << "Group: #{@group.name}"
    end
    
    q = Question
    
    if params[:privacy].present?
      @privacy = params[:privacy]
    end
    
    if @privacy == 'public'
      filter_description_array << "Public"
      q = q.public_visible
    elsif @privacy == 'switched_to_private'
      filter_description_array << "Switched to Private"
      q = q.switched_to_private
    elsif @privacy == 'private'
      filter_description_array << "Private"
      q = q.private
    end
    
    if @tag_pref.present?
      @tag = Tag.find_by_id(@tag_pref)
      filter_description_array << "Tag: #{@tag.name}"
      q = q.tagged_with(@tag_pref.to_i)
    end
    
    condition_array.empty? ? condition_string = nil : condition_string = condition_array.join(' AND ')
    filter_description_array.empty? ? @filter_string = nil : @filter_string = filter_description_array.join(' | ')
    
    if @status == 'answered'
      return q.answered.where(condition_string).order("questions.resolved_at DESC").page(params[:page])
    elsif @status == 'unanswered'
      return q.submitted.where(condition_string).order("questions.created_at DESC").page(params[:page])
    else
      return q.where(condition_string).order("questions.created_at DESC").page(params[:page])
    end
    
  end
  
  private
  
  def set_format
    request.format = 'html'
  end
  
end
