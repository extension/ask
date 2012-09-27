# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class UsersController < ApplicationController
  layout 'public'
  
  def show
    @user = User.find(params[:id])
    @answered_questions = @user.answered_questions.public_visible.limit(10)
    @open_questions = @user.open_questions.public_visible.limit(10)
  end
  
end