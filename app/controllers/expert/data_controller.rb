# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Expert::DataController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid

  def index
    if(params[:forcecacheupdate])
      options = {force: true}
    else
      options = {}
    end
    @question_stats = Question.answered_stats_by_yearweek('questions',options)
    @expert_stats = QuestionEvent.stats_by_yearweek(options)
    @responsetime_stats = Question.answered_stats_by_yearweek('responsetime',options)
    @evaluation_response_rate = EvaluationQuestion.mean_response_rate
    @demographic_response_rate = DemographicQuestion.mean_response_rate
  end



  def demographics
    @demographic_questions = DemographicQuestion.order(:questionorder).active
  end

  def evaluations
    @evaluation_questions = EvaluationQuestion.order(:questionorder).active
  end

  def questions
    @showform = (params[:showform] and TRUE_VALUES.include?(params[:showform]))

    if(params[:filter] && @question_filter = QuestionFilter.find_by_id(params[:filter]))
      @question_filter_objects = @question_filter.settings_to_objects
      @questions = Question.filtered_by(@question_filter).page(params[:page])
    else
      @questions = Question.page(params[:page])
    end
  end

  def filter_questions
    if(question_filter = QuestionFilter.find_or_create_by_settings(params,current_user))
      return redirect_to(questions_expert_data_url(filter: question_filter.id))
    else
      flash[:warning] = 'Invalid filter provided.'
      return redirect_to(questions_expert_data_url)
    end
  end



end
