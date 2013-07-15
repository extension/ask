# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class UsersController < ApplicationController
  layout 'public'
  
  before_filter :set_format, :only => [:show]
  
  def show
    @user = User.valid_users.find_by_id(params[:id])
    if @user.blank?
      flash[:error] = "This user does not exist."
      return redirect_to root_url
    end
    @answered_questions = @user.answered_questions.public_visible.limit(10)
    @open_questions = @user.open_questions.public_visible.limit(10)
  end
  
  def retired
  end
  
end