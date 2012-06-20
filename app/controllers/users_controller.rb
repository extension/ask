# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class UsersController < ApplicationController
  layout 'public'
  
  def show
    @user = User.find(params[:id])
    
    @fake_answered = Question.public_visible.find(:all, :limit => 10, :offset => rand(Question.count))
  end
  
end