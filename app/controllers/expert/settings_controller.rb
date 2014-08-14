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

    if !params[:id].present?
      redirect_to(expert_profile_settings_path(current_user.id))
    end

    @user = (params[:id].present? ? User.find_by_id(params[:id]) : current_user)
    if request.put?
      @user.attributes = params[:user]

      if params[:delete_avatar] && params[:delete_avatar] == "1"
        @user.avatar = nil
      end
      
      if @user.update_attributes(params[:person])
        what_changed = @user.previous_changes.reject{|attribute,value| (['updated_at'].include?(attribute) or ['avatar_content_type'].include?(attribute) or ['avatar_file_size'].include?(attribute) or ['avatar_updated_at'].include?(attribute) or (value[0].blank? and value[1].blank?))}
        
        UserEvent.log_generic_user_event(@user, current_user, what_changed, UserEvent::UPDATED_PROFILE)
      end
      if @user.save
        redirect_to(expert_user_path(@user.id), :notice => 'Profile was successfully updated.')
      else
        render :action => 'profile'
      end
    end
  end

  def tags
    if !params[:id].present?
      redirect_to(expert_tags_settings_path(current_user.id))
    end

    @user = (params[:id].present? ? User.find_by_id(params[:id]) : current_user)
  end

  def add_tag
    params[:id].present? ? @user = User.find_by_id(params[:id]) : @user = current_user
    # record tag and log changes
    change_hash = Hash.new
    previous_tags = @user.tags.map(&:name).join(', ')
    @tag = @user.set_tag(params[:tag])
    current_tags = @user.tags.map(&:name).join(', ')
    change_hash[:tags] = {:old => "", :new => @tag.name}
    UserEvent.log_added_tags(@user, current_user, change_hash) if previous_tags != current_tags

    if @tag.blank?
      render :nothing => true
    end
  end

  def remove_tag
    params[:id].present? ? @user = User.find_by_id(params[:id]) : @user = current_user
    tag = Tag.find(params[:tag_id])
    # record tag and log changes
    change_hash = Hash.new
    previous_tags = @user.tags.map(&:name).join(', ')
    @user.tags.delete(tag)
    current_tags = @user.tags.map(&:name).join(', ')
    change_hash[:tags] = {:old => tag.name, :new => ""}
    UserEvent.log_removed_tags(@user, current_user, change_hash) if previous_tags != current_tags

    # remove their listview prefs for this tag if it exists
    pref = @user.filter_preference
    if pref.present? && pref.setting[:question_filter][:tags].present? && pref.setting[:question_filter][:tags][0].to_i == tag.id
      pref.setting[:question_filter].merge!({:tags => nil})
      pref.save
    end
  end

  def profilelocation
    if !params[:id].present?
      redirect_to(expert_location_settings_path(current_user.id))
    end

    @user = (params[:id].present? ? User.find_by_id(params[:id]) : current_user)
    @locations = Location.order('fipsid ASC')
    @object = @user
  end

  def assignment
    if !params[:id].present?
      redirect_to(expert_assignment_settings_path(current_user.id))
    end

    @user = (params[:id].present? ? User.find_by_id(params[:id]) : current_user)

    if request.put?
      vacation_changed = false
      @user.attributes = params[:user]
      # log changes in expert history
      change_hash = Hash.new
      if @user.away_changed?
        vacation_changed = true
        change_hash[:vacation_status] = {:old => @user.away_was, :new => @user.away}
      end

      @user.save
      UserEvent.log_updated_vacation_status(@user, @user, change_hash) if vacation_changed
      flash[:notice] = "Preferences updated successfully!"
      render nil
    end
  end

end
