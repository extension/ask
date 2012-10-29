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
    @user = User.find(params[:id])
    @answered_questions = @user.answered_questions.limit(10)
    @open_questions = @user.open_questions.limit(10)
    @my_groups = @user.group_memberships
    @handling_event_count = @user.aae_handling_event_count 
  end
  
  def tags
    @tag = Tag.find_by_id(params[:tag_id])
    @user = User.find_by_id(params[:user_id])
    return record_not_found if (!@user || !@tag)
    @questions = @user.answered_questions.tagged_with(@tag.id).order("questions.status_state ASC")
  end
  
  def groups
    @user = User.find(params[:id])
    @my_groups = @user.group_memberships
  end
  
  def save_listview_filter
    user = current_user
    pref = user.user_preference
    
    if pref.nil?
      pref = UserPreference.create(:user => user, :setting => {:question_filter => {}})
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
    
end