# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DebugController < ApplicationController
  skip_before_filter :set_yolo, only: [:session_information]

  def session_information
    set_yolo if(!params[:skip_set_yolo])
  end
end