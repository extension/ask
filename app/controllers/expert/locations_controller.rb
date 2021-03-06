# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::LocationsController < ApplicationController
  layout 'expert'
  before_filter :signin_required
  


  def index
  end

  def show
    @location = Location.find_by_id(params[:id])
    @experts = User.with_expertise_location(@location.id).exid_holder.not_unavailable.order("users.last_activity_at DESC").limit(5)
    @expert_total_count = User.with_expertise_location(@location.id).exid_holder.not_unavailable.count
    @groups = Group.where(group_active: true).with_expertise_location(@location.id).limit(5)
    @group_total_count_active = Group.where(group_active: true).with_expertise_location(@location.id).count
    @group_total_count_inactive = Group.where(group_active: false).with_expertise_location(@location.id).count
    @unanswered_questions_count = Question.where("location_id = ?", @location.id).submitted.not_rejected.count
    @counties = @location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
  end

  def primary_groups
    @location = Location.find_by_id(params[:id])
  end

  def message
    @location = Location.find_by_id(params[:id])
  end

  def set_message
    @location = Location.find_by_id(params[:id])
    if(params[:location] and params[:location][:message])
      @location.set_message(params[:location][:message],current_user)
      flash[:success] = "Custom message set."
    end
    return redirect_to(expert_location_path(@location))
  end

  def add_primary_group
    location = Location.find(params[:id])
    group = Group.find(params[:group_id])
    #TODO  active check
    location.add_primary_group(group,current_user)
    return redirect_to primary_groups_expert_location_path(id: location.id)
  end

  def remove_primary_group
    location = Location.find(params[:id])
    group = Group.find(params[:group_id])
    location.remove_primary_group(group,current_user)
    return redirect_to primary_groups_expert_location_path(id: location.id)
  end


  def experts
    @location = Location.find(params[:id])
    @experts = User.with_expertise_location(@location.id).exid_holder.not_unavailable.page(params[:page]).order("users.last_activity_at DESC")
    @expert_total_count = User.with_expertise_location(@location.id).exid_holder.not_unavailable.count
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @experts.map(&:id)})
  end


  def experts_email_csv
    @location = Location.find_by_id(params[:id])
    return record_not_found if @location.blank?
    @experts = User.with_expertise_location(@location.id).exid_holder.not_unavailable.order("users.last_activity_at DESC")
    respond_to do |format|
      format.csv { send_data User.to_csv(@experts, ["first_name", "last_name", "email"]), :filename => "#{@location.name.gsub(' ', '_')}_Expert_Emails.csv" }
    end
  end



end
