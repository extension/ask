# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::UsersController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def show
    @user = User.exid_holder.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "The user specified does not exist as an expert in AaE."
      return redirect_to expert_home_url 
    end
    @question_list = "assigned"
    @questions = @user.open_questions.page(params[:page]).order('created_at DESC')
    @question_count = @user.open_questions.length
    @my_groups = @user.group_memberships
    @handling_event_count = @user.aae_handling_event_count 
  end
  
  def status
    @user = User.find_by_id(params[:id])
    
    if request.put?
      @user.update_attributes(params[:user])
      flash[:notice] = "Preferences updated successfully!"
      render nil
    end
  end
  
  def answered
    @user = User.exid_holder.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "The user specified does not exist as an expert in AaE."
      return redirect_to expert_home_url 
    end
    @question_list = "answered"
    @questions = @user.answered_questions.page(params[:page]).order('created_at DESC')
    @question_count = @user.answered_questions.length
    @my_groups = @user.group_memberships
    @handling_event_count = @user.aae_handling_event_count
    render :action => 'show'
  end
  
  def watched
    @user = User.exid_holder.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "The user specified does not exist as an expert in AaE."
      return redirect_to expert_home_url 
    end
    @question_list = "watched"
    @questions = @user.watched_questions.page(params[:page]).order('created_at DESC')
    @question_count = @user.watched_questions.length
    @my_groups = @user.group_memberships
    @handling_event_count = @user.aae_handling_event_count
    render :action => 'show'
  end
  
  def rejected
    @user = User.exid_holder.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "The user specified does not exist as an expert in AaE."
      return redirect_to expert_home_url 
    end
    @question_list = "rejected"
    @questions = @user.rejected_questions.page(params[:page]).order('created_at DESC')
    @question_count = @user.rejected_questions.length
    @my_groups = @user.group_memberships
    @handling_event_count = @user.aae_handling_event_count
    render :action => 'show'
  end
  
  def tags
    @tag = Tag.find_by_id(params[:tag_id])
    @user = User.exid_holder.find_by_id(params[:user_id])
    return record_not_found if (!@user || !@tag)
    @questions = @user.answered_questions.tagged_with(@tag.id).order("questions.status_state ASC")
  end
  
  def groups
    @user = User.exid_holder.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "The user specified does not exist as an expert in AaE."
      return redirect_to expert_home_url 
    end
    @my_groups = @user.group_memberships
  end
  
  def save_listview_filter
    user = current_user
    pref = user.filter_preference
    
    if pref.nil?
      pref = FilterPreference.create(:user => user, :setting => {:question_filter => {}})
    end
    
    if !params[:location_id].nil?
      if params[:location_id].blank?
        pref.setting[:question_filter].merge!({:locations => nil, :counties => nil})
      else
        location = Location.find_by_id(params[:location_id])
        pref.setting[:question_filter].merge!({:locations => [location.id], :counties => nil})
      end
      pref.save
    elsif !params[:county_id].nil?
      if params[:county_id].blank?
        pref.setting[:question_filter].merge!({:counties => nil})
      else
        county = County.find_by_id(params[:county_id])
        pref.setting[:question_filter].merge!({:counties => [county.id]})
      end
      pref.save
    elsif !params[:group_id].nil?
      if params[:group_id].blank?
        pref.setting[:question_filter].merge!({:groups => nil})
      else
        group = Group.find_by_id(params[:group_id])
        pref.setting[:question_filter].merge!({:groups => [group.id]})
      end
      pref.save
    elsif !params[:tag_id].nil?
      if params[:tag_id].blank?
        pref.setting[:question_filter].merge!({:tags => nil})
      else
        tag = Tag.find_by_id(params[:tag_id])
        pref.setting[:question_filter].merge!({:tags => [tag.id]})
      end
      pref.save
    end
    
    @recent_questions = questions_based_on_pref_filter(params[:list_view], pref)  
  end
  
  def save_notification_prefs
    user = current_user
    if params[:group_id].present? 
      send_incoming_notification = params[:send_incoming_notification].present?
      Preference.create_or_update(user, Preference::NOTIFICATION_INCOMING, send_incoming_notification, params[:group_id])
      send_daily_summary =  params[:send_daily_summary].present?
      Preference.create_or_update(user, Preference::NOTIFICATION_DAILY_SUMMARY, send_daily_summary, params[:group_id])
    end
    redirect_to :back
  end
    
end