# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::HomeController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def index
    @recent_questions = Question.find(:all, :limit => 20, :order => 'created_at DESC')
    @locations = Location.order('fipsid ASC')
    @my_groups = current_user.group_memberships
    @my_tags = current_user.tags
  end
  
  def search
  end
  
  def get_counties
    render :partial => "counties"
  end
  
  def answered
    @recently_answered_questions = Question.answered.find(:all, :limit => 20, :order => 'created_at DESC')
    @locations = Location.order('fipsid ASC')
    @my_groups = current_user.group_memberships
  end
  
  def tags
    @tag = Tag.find_by_name(params[:id])
    return record_not_found if (!@tag)
    @questions = Question.tagged_with(@tag.id).order("questions.status_state ASC").limit(25)
  end
  
  def experts
    @tag = Tag.find_by_id(params[:tag_id])
    return record_not_found if (!@tag)
    @experts = User.tagged_with(@tag.id)
  end
  
  def locations
    @location = Location.find_by_id(params[:id])
    @counties = @location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    
    @questions = Question.where("location_id = ?", @location.id).order("questions.status_state DESC").limit(8)
    @question_total_count = Question.where("location_id = ?", @location.id).count
    @experts = User.with_expertise_location(@location.id).order("users.last_sign_in_at ASC").limit(8)
    @expert_total_count = User.with_expertise_location(@location.id).count
    @groups = Group.with_expertise_location(@location.id).limit(8)
    @group_total_count = Group.with_expertise_location(@location.id).count
  end
  
  def county
    @county = County.find_by_id(params[:id])
    @location = Location.find_by_id(@county.location_id)
    
    @questions = Question.where("county_id = ?", @county.id).order("questions.status_state DESC").limit(8)
    @question_total_count = Question.where("county_id = ?", @county.id).count
    @experts = User.with_expertise_county(@county.id).order("users.last_sign_in_at ASC").limit(8)
    @expert_total_count = User.with_expertise_county(@county.id).count
    @groups = Group.with_expertise_county(@county.id).limit(8)
    @group_total_count = Group.with_expertise_county(@county.id).count
  end
end
