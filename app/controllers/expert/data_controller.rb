# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AaeController < ApplicationController

  def index
    if(params[:forcecacheupdate])
      options = {force: true}
    else
      options = {}
    end
    @question_stats = Question.answered_stats_by_yearweek('questions',options)
    @expert_stats = QuestionActivity.stats_by_yearweek(options)
    @responsetime_stats = Question.answered_stats_by_yearweek('responsetime',options)
    @evaluation_response_rate = AaeEvaluationQuestion.mean_response_rate
    @demographic_response_rate = AaeDemographicQuestion.mean_response_rate
  end



  def demographics
    @demographic_questions = AaeDemographicQuestion.order(:questionorder).active
  end

  def evaluations
    @evaluation_questions = AaeEvaluationQuestion.order(:questionorder).active

  end

end
