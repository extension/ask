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
    # no linking directly to this page from outside site
    if(!refered_from_our_site?)
      return redirect_to(ask_index_path)
    end

    @location = Location.find(params[:id])
    @yolo.set_location(@location)
  end

end
