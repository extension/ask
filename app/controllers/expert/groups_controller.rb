# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::GroupsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def index
    @my_groups = current_user.group_memberships
    @groups = Group.paginate(:page => params[:page]).order(:name)
  end
  
  def show
    @group = Group.find(params[:id])
    if !@group 
      return record_not_found
    end
    
    @open_questions = @group.open_questions
  end
  
  
  
  
  
end