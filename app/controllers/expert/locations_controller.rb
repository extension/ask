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
    location = Location.find(params[:id])
    group = Group.find(params[:group_id])
    # todo active check
    location.add_primary_group(group,current_user)
    return redirect_to primary_groups_expert_location_path(id: location.id)
  end

  def remove_primary_group
    location = Location.find(params[:id])
    group = Group.find(params[:remove_group_id])
    location.remove_primary_group(group,current_user)
    return redirect_to primary_groups_expert_location_path(id: location.id)
  end

end
