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
    @user = User.find(params[:id])
    @answered_questions = @user.answered_questions.limit(10)
    @open_questions = @user.open_questions.limit(10)
    @my_groups = @user.group_memberships
  end
  
  def tags
    @tag = Tag.find_by_id(params[:tag_id])
    @user = User.find_by_id(params[:user_id])
    return record_not_found if (!@user || !@tag)
    @questions = @user.answered_questions.tagged_with(@tag.id).order("questions.status_state ASC")
  end
  
  def groups
    @user = User.find(params[:id])
    @my_groups = @user.group_memberships
  end
end