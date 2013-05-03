# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::HomeController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def index
    @user = current_user
    if(params[:user_id])
      @user = User.find_by_id(params[:user_id])
      if !@user.present?
        flash[:error] = "There's no expert with the ID \"#{params[:user_id]}\"."
        return redirect_to expert_home_url
      end
    end
    
    @my_groups = @user.group_memberships.except(:order).find(:all, :select => "groups.*", :joins => "LEFT JOIN questions on groups.id = questions.assigned_group_id", :group => "groups.id", :order => "COUNT(IF(questions.status_state = #{Question::STATUS_SUBMITTED}, questions.id, NULL)) DESC, groups.name")
    @all_unanswered_questions_count = Question.submitted.not_rejected.count
    @oldest_assigned_question = @user.open_questions.order('created_at ASC').first
    @questions_assigned_to_expert_count = @user.open_questions.length
    
    @date = DateTime.now
    @year_month = User.year_month_string(Date.today.year,Date.today.month)
    
    @questions_asked = Question.not_rejected.asked_list_for_year_month(@year_month).order('created_at DESC')
    @questions_answered = Question.not_rejected.answered_list_for_year_month(@year_month).order('created_at DESC')
    
    @assigned = @user.assigned_list_for_year_month(@year_month)
    @answered = @user.answered_list_for_year_month(@year_month)
    @touched = @user.touched_list_for_year_month(@year_month)
  end
    
  def dashboard
    redirect_to expert_home_path()
  end
  
  def search
  end
  
  def get_counties
    render :partial => "counties", :locals => {:location_obj => nil}
  end
    
  def tags
    @tag = Tag.find_by_name(params[:name])
    if @tag
      @unanswered_questions_count = Question.tagged_with(@tag.id).submitted.not_rejected.count
      
      @questions = Question.tagged_with(@tag.id).not_rejected.order("questions.created_at DESC").limit(25)
      @question_total_count = Question.tagged_with(@tag.id).order("questions.status_state ASC").count
    
      @experts = User.tagged_with(@tag.id).order("users.last_active_at DESC").limit(5)
      @expert_total_count = User.tagged_with(@tag.id).count
      @groups = Group.tagged_with(@tag.id).limit(5)
      @group_total_count = Group.tagged_with(@tag.id).count
    else
      @tag = false
      @tag_name = params[:name]
    end
  end
  
  def users_by_tag
    @tag = Tag.find_by_name(params[:name])
    return record_not_found if (!@tag)
    @experts = User.tagged_with(@tag.id).page(params[:page]).exid_holder.not_retired.order("users.last_active_at DESC")
    @expert_total_count = User.tagged_with(@tag.id).count
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @experts.map(&:id)})
  end
  
  def groups_by_tag
    @tag = Tag.find_by_name(params[:name])
    return record_not_found if (!@tag)
    @groups = Group.tagged_with(@tag.id).page(params[:page])
    @group_total_count = Group.tagged_with(@tag.id).count
  end
  
  def questions_by_tag
    @tag = Tag.find_by_name(params[:name])
    return record_not_found if (!@tag)
    @questions = Question.tagged_with(@tag.id).not_rejected.page(params[:page]).order("questions.created_at DESC")
  end
  
  def users_by_location
    @location = Location.find_by_id(params[:id])
    return record_not_found if @location.blank?
    @experts = User.with_expertise_location(@location.id).exid_holder.not_retired.page(params[:page]).order("users.last_active_at DESC")
    @expert_total_count = User.with_expertise_location(@location.id).exid_holder.not_retired.count
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @experts.map(&:id)})
  end
  
  def users_by_county
    @county = County.find_by_id(params[:id])
    return record_not_found if @county.blank?
    @experts = User.with_expertise_county(@county.id).exid_holder.not_retired.page(params[:page]).order("users.last_active_at DESC")
    @expert_total_count = User.with_expertise_county(@county.id).exid_holder.not_retired.count
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @experts.map(&:id)})
  end
  
  def groups_by_location
    @location = Location.find_by_id(params[:id])
    return record_not_found if @location.blank?
    @groups = Group.with_expertise_location(@location.id).page(params[:page])
    @group_total_count = Group.with_expertise_location(@location.id).count
  end
  
  def groups_by_county
    @county = County.find_by_id(params[:id])
    return record_not_found if @county.blank?
    @groups = Group.with_expertise_county(@county.id).page(params[:page])
    @group_total_count = Group.with_expertise_county(@county.id).count
  end
  
  def questions_by_location
    @location = Location.find_by_id(params[:id])
    return record_not_found if @location.blank?
    @questions = Question.where("location_id = ?", @location.id).not_rejected.page(params[:page]).order("questions.status_state ASC")
    @question_total_count = Question.where("location_id = ?", @location.id).not_rejected.count
  end
  
  def questions_by_county
    @county = County.find_by_id(params[:id])
    return record_not_found if @county.blank?
    @questions = Question.where("county_id = ?", @county.id).not_rejected.page(params[:page]).order("questions.status_state DESC")
    @question_total_count = Question.where("county_id = ?", @county.id).not_rejected.count
  end
  
  def locations
    @location = Location.find_by_id(params[:id])
    @counties = @location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    
    @questions = Question.where("location_id = ?", @location.id).not_rejected.order("questions.status_state DESC").limit(8)
    @unanswered_questions = Question.where("location_id = ?", @location.id).submitted.not_rejected.order("questions.status_state DESC").limit(8)
    @unanswered_questions_count = Question.where("location_id = ?", @location.id).submitted.not_rejected.count
    @question_total_count = Question.where("location_id = ?", @location.id).not_rejected.count
    @experts = User.with_expertise_location(@location.id).exid_holder.not_retired.order("users.last_active_at DESC").limit(5)
    @expert_total_count = User.with_expertise_location(@location.id).exid_holder.not_retired.count
    @groups = Group.with_expertise_location(@location.id).limit(5)
    @group_total_count = Group.with_expertise_location(@location.id).count
  end
  
  def county
    @county = County.find_by_id(params[:id])
    return record_not_found if @county.blank?
    @location = Location.find_by_id(@county.location_id)
    @locations = Location.order('fipsid ASC')
    
    @unanswered_questions_count = Question.where("county_id = ?", @county.id).submitted.not_rejected.count
    
    @questions = Question.where("county_id = ?", @county.id).not_rejected.order("questions.status_state DESC").limit(5)
    @question_total_count = Question.where("county_id = ?", @county.id).not_rejected.count
    @experts = User.with_expertise_county(@county.id).exid_holder.not_retired.order("users.last_active_at DESC").limit(5)
    @expert_total_count = User.with_expertise_county(@county.id).exid_holder.not_retired.count
    @groups = Group.with_expertise_county(@county.id).limit(8)
    @group_total_count = Group.with_expertise_county(@county.id).count
  end
  
  def managetags
    @tags_total_count = Tag.used_at_least_once.length
    @tags = Tag.used_at_least_once.order('tags.name ASC').page(params[:page]).per(50)
  end
end
