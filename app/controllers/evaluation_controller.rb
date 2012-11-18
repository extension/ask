# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class EvaluationController < ApplicationController
  before_filter :set_evaluator


  def question
    @question = Question.last
  end

  def demographics_test
  end

  def answer_demographic
    @demographic_question = DemographicQuestion.find(params[:demographic_question_id])
    @demographic_question.create_or_update_answers(user: @evaluator, params: params)
    return render :json => {'success'=> true}.to_json, :status => :ok
  end

  def answer_evaluation
    @question = Question.find(params[:question_id])
    @evaluation_question = EvaluationQuestion.find(params[:evaluation_question_id])
    @evaluation_question.create_or_update_answers(user: @evaluator, question: @question, params: params)
    return render :json => {'success'=> true}.to_json, :status => :ok
  end

  private

  def set_evaluator
    if(current_user)
      @evaluator = current_user
    elsif(session[:submitter_id])
      @evaluator = User.find_by_id(session[:submitter_id])
    end
  end

end