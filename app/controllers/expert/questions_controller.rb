# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::QuestionsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def show
    @question = Question.find_by_id(params[:id])
    @question_responses = @question.responses
    @fake_related = Question.find(:all, :limit => 3, :offset => rand(Question.count))
  end
end
