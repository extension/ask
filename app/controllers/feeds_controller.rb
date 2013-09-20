# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class FeedsController < ApplicationController
  def answered_questions
    @questions = Question.public_visible_answered.order('resolved_at DESC').limit(((params[:limit].present?) && (params[:limit].to_i > 0)) ? params[:limit] : 10)
    respond_to do |format|
      format.xml { render :layout => false, :content_type => "application/atom+xml" }
    end  
  end
end
