# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LocationsController < ApplicationController
  layout 'public'

  def index
  end

  def show
    @location = Location.find(params[:id])
  end

end
