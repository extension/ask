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
    if(params[:id] and params[:id].length == 32)
      return redirect_to(submitter_view_url(fingerprint: params[:id]))
    end
    @location = Location.find(params[:id])
    @yolo.set_location(@location)

    # ask tracking
    create_location_track(@location)
  end


  def create_location_track(location)
    return true if request.bot?
    location_track = LocationTrack.create(ipaddr: request.remote_ip,
                                          referer_track_id: session[:rt],
                                          location_id: location.id,
                                          group_count: location.active_primary_groups.count)
    session[:lt] = location_track.id
  end

end
