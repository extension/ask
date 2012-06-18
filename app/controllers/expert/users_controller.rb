# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::UsersController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def show
    @user = User.find(:first, :conditions => {:id => params[:id]})
    return record_not_found if !@user
    
    @answered_questions = @user.answered_questions.limit(10)
  end
  
end