# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class GroupsController < ApplicationController
  layout 'public'
  
  def show
    @group = Group.find(params[:id])
    @group_tags = @group.tags
    @open_questions = @group.open_questions.public_visible.find(:all, :limit => 10, :order => 'created_at DESC')
  end
  
  def ask
    @group = Group.find(params[:id])
    params[:fingerprint] = @group.widget_fingerprint
  end
  
end