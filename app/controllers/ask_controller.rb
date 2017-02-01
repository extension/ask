# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class AskController < ApplicationController
  layout 'public'

  def index
  end

  def show
    @location = Location.find(params[:id])
    @yolo.set_location(@location)

    # ask tracking
    create_location_track(@location)
  end


  def create_location_track(location)
    location_track = LocationTrack.create(ipaddr: request.remote_ip,
                                          referer_track_id: session[:rt],
                                          location_id: location.id,
                                          group_count: location.active_primary_groups.count)
    session[:lt] = location_track.id
  end

end
