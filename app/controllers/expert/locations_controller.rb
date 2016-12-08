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
    @locations = Location.displaylist.includes(:groups)

  end


end
