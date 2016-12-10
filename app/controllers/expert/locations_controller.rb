# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::LocationsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid


  def index
  end

  def show
    @location = Location.find_by_id(params[:id])
    @experts = User.with_expertise_location(@location.id).exid_holder.not_retired.order("users.last_active_at DESC").limit(5)
    @expert_total_count = User.with_expertise_location(@location.id).exid_holder.not_retired.count
    @groups = Group.with_expertise_location(@location.id).limit(5)
    @group_total_count = Group.with_expertise_location(@location.id).count
  end

  def primary_groups
    @location = Location.find_by_id(params[:id])
  end

  def add_primary_group
    location = Location.find_by_id(params[:id])
    group = Group.find_by_id(params[:group_id])

    # when adding location, start out with the all county selection
    group.expertise_counties << location.get_all_county unless group.expertise_counties.include?(location.get_all_county)

    if !group.expertise_locations.include?(location)
      group.expertise_locations << location
    end

    gl = group.group_locations.where("location_id = ?", location.id)
    @group_location = GroupLocation.find(gl.first.id)
    @group_location.update_attributes({:is_primary => true})

    change_hash = Hash.new
    change_hash[:expertise_locations] = {:old => "", :new => location.name}
    UserEvent.log_added_location(group, current_user, change_hash)

    return redirect_to expert_locations_path
  end

  def remove_primary_group
  end

end
