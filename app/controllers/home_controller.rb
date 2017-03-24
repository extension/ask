# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class HomeController < ApplicationController
  layout 'public'
  before_filter :set_format, :only => [:about, :index]

  def index
    @answered_questions = Question.public_visible_answered.page(params[:page]).order('created_at DESC')
    @recent_photo_questions = Question.public_visible_with_images_answered.order('questions.created_at DESC').limit(6)
  end

  def unanswered
    @unanswered_questions = Question.public_visible_unanswered.page(params[:page]).order('created_at DESC')
    @recent_photo_questions = Question.public_visible_with_images_unanswered.order('questions.created_at DESC').limit(6)
    if current_location
      @groups = Group.assignable.with_expertise_location(current_location.id).limit(6)
    end
  end

  def private_page
  end

  def accept_questions
    if current_user
      @my_groups = current_user.group_memberships
    end
  end

  def about
  end

  def locations
    @location = Location.find_by_id(params[:id])
    return record_not_found if (!@location)
    @counties = @location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")

    @questions = Question.public_visible.where("location_id = ?", @location.id).order("questions.status_state DESC").limit(8)
    @question_total_count = Question.public_visible.where("location_id = ?", @location.id).count
    @experts = User.not_retired.with_expertise_location(@location.id).order("users.last_active_at ASC").limit(8)
    @expert_total_count = User.with_expertise_location(@location.id).count
    @groups = Group.with_expertise_location(@location.id).limit(8)
    @group_total_count = Group.with_expertise_location(@location.id).count
  end

  def county
    @county = County.find_by_id(params[:id])
    return record_not_found if (!@county)
    @location = Location.find_by_id(@county.location_id)

    @questions = Question.public_visible.where("county_id = ?", @county.id).order("questions.status_state DESC").limit(8)
    @question_total_count = Question.public_visible.where("county_id = ?", @county.id).count
    @experts = User.not_retired.with_expertise_county(@county.id).order("users.last_active_at ASC").limit(8)
    @expert_total_count = User.with_expertise_county(@county.id).count
    @groups = Group.with_expertise_county(@county.id).limit(8)
    @group_total_count = Group.with_expertise_county(@county.id).count
  end

  def questions_by_tag
    @tag = Tag.find_by_name(params[:name])
    return record_not_found if (!@tag)
    @questions = Question.public_visible.tagged_with(@tag.id).not_rejected.page(params[:page]).order("questions.created_at DESC")
  end

  def county_options_list
    render partial: 'county_select'
  end

  def change_yolo
    if(@yolo)
      if(params[:location_id])
        # should 404 on failure
        location = Location.find(params[:location_id])
        @yolo.set_location(location)
      end

      if(params[:county_id])
        # should 404 on failure
        county = County.find(params[:county_id])
        @yolo.set_county(county)
      end

      if current_location
        @groups = Group.assignable.with_expertise_location(current_location.id).limit(6)
      end
    end
  end

end
