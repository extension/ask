# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::SettingsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def profile
    @user = current_user
    if request.put?
      @user.attributes = params[:user]
      
      if params[:delete_avatar] && params[:delete_avatar] == "1"
        @user.avatar = nil
      end
      
      if @user.save
        redirect_to(expert_settings_profile_path, :notice => 'Profile was successfully updated.')
      else
        render :action => 'profile'
      end
    end
  end
  
  def tags
    @user = current_user
  end
  
  def add_tag
    @user = current_user
    @tag = @user.set_tag(params[:tag])
    if @tag == false
      render :nothing => true
    end
  end
  
  def remove_tag
    @user = current_user
    tag = Tag.find(params[:tag_id])
    @user.tags.delete(tag)
    # remove their listview prefs for this tag if it exists
    pref = @user.filter_preference
    if pref.present? && pref.setting[:question_filter][:tags].present? && pref.setting[:question_filter][:tags][0].to_i == tag.id
      pref.setting[:question_filter].merge!({:tags => nil})
      pref.save
    end
  end
  
  def location
    @user = current_user
    @locations = Location.order('fipsid ASC')
    @object = @user
  end
  
  def assignment
    @user = current_user
    
    if request.put?
      @user.update_attributes(params[:user])
      flash[:notice] = "Preferences updated successfully!"
      render nil
    end
  end

end
