# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class DebugController < ApplicationController
  skip_before_filter :set_yolo, only: [:session_information]
  before_filter :require_exid, only: [:signatures]


  def session_information
    set_yolo if(!params[:skip_set_yolo])
  end

  def signatures
    @userlist = User.where("length(signature) > 0").where("signature != CONCAT('-',first_name,' ',last_name)").order("length(signature) DESC").page(params[:page]).per(100)
  end

end