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

  end

end
