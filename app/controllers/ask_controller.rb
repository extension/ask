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
  end

end
