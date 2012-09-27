# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class HomeController < ApplicationController
  layout 'public'
  
  def index
    @recent_questions = Question.public_visible.find(:all, :limit => 10, :order => 'created_at DESC')
  end
  
  def private_page
  end
  
  def about
  end
  
  def locations
    @location = Location.find_by_id(params[:id])
    @counties = @location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    
    @questions = Question.public_visible.where("location_id = ?", @location.id).order("questions.status_state DESC").limit(8)
    @question_total_count = Question.public_visible.where("location_id = ?", @location.id).count
    @experts = User.with_expertise_location(@location.id).order("users.last_sign_in_at ASC").limit(8)
    @expert_total_count = User.with_expertise_location(@location.id).count
    @groups = Group.with_expertise_location(@location.id).limit(8)
    @group_total_count = Group.with_expertise_location(@location.id).count
  end
  
  def county
    @county = County.find_by_id(params[:id])
    @location = Location.find_by_id(@county.location_id)
    
    @questions = Question.public_visible.where("county_id = ?", @county.id).order("questions.status_state DESC").limit(8)
    @question_total_count = Question.public_visible.where("county_id = ?", @county.id).count
    @experts = User.with_expertise_county(@county.id).order("users.last_sign_in_at ASC").limit(8)
    @expert_total_count = User.with_expertise_county(@county.id).count
    @groups = Group.with_expertise_county(@county.id).limit(8)
    @group_total_count = Group.with_expertise_county(@county.id).count
  end
end
