# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DebugController < ApplicationController
  skip_before_filter :set_session_location, only: [:session_information]

  def session_information
    set_session_location if(!params[:skip_set_session_location])
    if(params[:detected_location_id])
      session[:location_data][:detected][:location_id] = params[:detected_location_id]
    end

    if(params[:location_id])
      session[:location_data][:personal][:location_id] = params[:location_id]
    end 
  end
end