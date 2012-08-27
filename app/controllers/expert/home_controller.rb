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
    @recent_questions = Question.find(:all, :limit => 10, :order => 'created_at DESC')
  end
  
  def tags
    @tag = Tag.find_by_id(params[:tag_id])
    return record_not_found if (!@tag)
    @questions = Question.tagged_with(@tag.id).order("questions.status_state ASC")
  end
  
  def experts
    @tag = Tag.find_by_id(params[:tag_id])
    return record_not_found if (!@tag)
    @experts = User.tagged_with(@tag.id)
  end
end
