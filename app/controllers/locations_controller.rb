# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LocationsController < ApplicationController
  layout 'public'

  before_filter :set_format, :only => [:ask]
  invisible_captcha only: [:create]

  def index
  end

  def show
    @location = Location.find(params[:id])
  end

end
