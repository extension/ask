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
    @group_members = @group.joined.limit(5)
    @group_members_total = @group.joined.count
    @group_tags = @group.tags
  end
  
  def members
    @group = Group.find(params[:id])
    @group_members = @group.joined
  end
  
  def questions_by_tag
    @group = Group.find_by_id(params[:group_id])
    @tag = Tag.find_by_id(params[:tag_id])
    
    return record_not_found if (!@group || !@tag)
    
    @questions = Question.from_group(@group.id).tagged_with(@tag.id).order("questions.status_state ASC")
  end
  
  def profile
    @group = Group.find_by_id(params[:id])
    if request.put?
      @group.attributes = params[:group]
      
      if @group.save
        redirect_to(expert_group_profile_path, :notice => 'Profile was successfully updated.')
      else
        render :action => 'profile'
      end
    end
  end
  
  def locations
    @group = Group.find_by_id(params[:id])
    @locations = Location.order('fipsid ASC')
    @object = @group
  end
  
  def tags
    @group = Group.find_by_id(params[:id])
    @group_tags = @group.tags.order('name ASC')
  end
  
  def add_tag
    @group = Group.find_by_id(params[:id])
    @tag = @group.set_tag(params[:tag])
    if @tag == false
      render :nothing => true
    end
  end
  
  def remove_tag
    @group = Group.find_by_id(params[:id])
    tag = Tag.find(params[:tag_id])
    @group.tags.delete(tag)
  end
  
  
  def assignment_options
    @group = Group.find_by_id(params[:id])
    if request.put?
      @group.attributes = params[:group]
      
      if @group.save
        redirect_to(expert_group_assignment_options_path, :notice => 'Assignment preferences updated.')
      else
        render :action => 'assignment_options'
      end
    end
  end
  
  def widget
    @group = Group.find_by_id(params[:id])
    if request.post?
      
      if params[:active].present? && params[:active] == '1'
        @group.active = true
      else
        @group.active = false
      end
      
      if params[:widget_upload_capable].present? && params[:widget_upload_capable] == '1'
        @group.widget_upload_capable = true
      else
        @group.widget_upload_capable = false
      end
      
      if params[:widget_public_option].present? && params[:widget_public_option] == '1'
        @group.widget_public_option = true
      else
        @group.widget_public_option = false
      end
      
      if params[:widget_show_location].present? && params[:widget_show_location] == '1'
        @group.widget_show_location = true
      else
        @group.widget_show_location = false
      end
      
      if @group.save
        redirect_to(expert_group_widget_path, :notice => 'Widget settings successfully updated.')
      else
        render :action => 'widget'
      end
    end
  end
  
  def history
    @group = Group.find_by_id(params[:id])
  end
  
end