# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ApplicationController < ActionController::Base
  require_dependency 'year_week_stats'

  helper_method :current_location
  helper_method :current_county
  before_filter :set_time_zone_from_user, :set_last_active_at_for_user

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
  
  
  def questions_based_on_report_filter(status="unanswered", year_month)
    condition_array = Array.new
    
    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      condition_array << "questions.location_id = #{@location.id}"
    end
    
    if params[:county_id].present?
      @county = County.find_by_id(params[:county_id])
      condition_array << "questions.county_id = #{@county.id}"
    end
    
    if params[:group_id].present?
      @group = Group.find(params[:group_id])
      condition_array << "questions.assigned_group_id = #{@group.id}"
    end
    
    condition_array.empty? ? condition_string = nil : condition_string = condition_array.join(' AND ')
    
    if status == "answered"
      return Question.not_rejected.where(condition_string).answered_list_for_year_month(@year_month).order('created_at DESC')
    elsif status == "asked"
      return Question.not_rejected.where(condition_string).asked_list_for_year_month(@year_month).order('created_at DESC')
    else
      return Question.submitted.not_rejected.where(condition_string).order('created_at DESC')
    end
  end
  
  def questions_based_on_pref_filter(list_view, filter_pref)
    condition_array = Array.new
    if filter_pref
      filter_pref.setting[:question_filter][:locations].present? ? @location_pref = filter_pref.setting[:question_filter][:locations][0].to_i : @location_pref = nil
      filter_pref.setting[:question_filter][:counties].present? ? @county_pref = filter_pref.setting[:question_filter][:counties][0].to_i : @county_pref = nil
      filter_pref.setting[:question_filter][:groups].present? ? @group_pref = filter_pref.setting[:question_filter][:groups][0].to_i : @group_pref = nil
      filter_pref.setting[:question_filter][:tags].present? ? @tag_pref = filter_pref.setting[:question_filter][:tags][0].to_i : @tag_pref = nil 
    end
    
    
    if params[:override].present?
      @location_pref = params[:location_id]
      @county_pref = params[:county_id]
      @group_pref = params[:group_id]
      @tag_pref = params[:tag_id]
    end
    
    @filter_description = ""

    
    if @location_pref.present?
      condition_array << "questions.location_id = #{@location_pref.to_i}"
      @location = Location.find_by_id(@location_pref)
      @filter_description += " #{@location.name} "
    end
    
    if @county_pref.present?
      condition_array << "questions.county_id = #{@county_pref.to_i}"
      @county = County.find_by_id(@county_pref)
      @filter_description += " #{@county.name} "
    end
    
    if @group_pref.present?
      condition_array << "questions.assigned_group_id = #{@group_pref.to_i}"
      @group = Group.find_by_id(@group_pref)
      @filter_description += " #{@group.name} "
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
      @tag = Tag.find_by_id(@tag_pref)
      @filter_description += " #{@tag.name} "
      if !list_view.present?
        return Question.tagged_with(@tag_pref.to_i).where(condition_string).order(question_order).page(params[:page])
      elsif list_view == 'resolved'
        return Question.answered.tagged_with(@tag_pref.to_i).where(condition_string).order(question_order).page(params[:page])
      elsif list_view == 'incoming'
        return Question.submitted.tagged_with(@tag_pref.to_i).where(condition_string).order(question_order).page(params[:page])
      end
    else
      if !list_view.present?
        return Question.where(condition_string).order(question_order).page(params[:page])
      elsif list_view == 'resolved'
        return Question.answered.where(condition_string).order(question_order).page(params[:page])
      elsif list_view == 'incoming'
        return Question.submitted.where(condition_string).order(question_order).page(params[:page])
      end
    end
  end
  
  private
  
  def set_format
    request.format = 'html'
  end
  
end
