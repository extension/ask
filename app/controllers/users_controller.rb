# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class UsersController < ApplicationController
  layout 'public'
  
  def show
    @user = User.find(:first, :conditions => {:id => params[:id]})
    return record_not_found if !@user
  end
  
end