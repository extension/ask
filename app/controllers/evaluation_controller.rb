# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class EvaluationController < ApplicationController
  before_filter :signin_required, only: [:example]
  before_filter :set_format, :only => [:view]

  def view
    @page_title = 'Evaluation Questions'
    @question = Question.find_by_question_fingerprint(params[:fingerprint])
    if @question.present?
      @evaluator = @question.submitter
      session[:evaluator_id] = @evaluator.id
    else
      return record_not_found
    end
  end

  def example
    @evaluator = current_user
    @question = Question.last
    @page_title = 'Example Evaluation Questions'
    @question_testing = true
    return render(template: 'evaluation/view')
  end

  def answer_demographic
    if(session[:evaluator_id] and @evaluator = User.find_by_id(session[:evaluator_id]))
      @demographic_question = DemographicQuestion.find(params[:demographic_question_id])
      @demographic_question.create_or_update_answers(user: @evaluator, params: params)
      return render :json => {'success'=> true}.to_json, :status => :ok
    else
      # silent failure
      return render :json => {'success'=> false}.to_json, :status => :ok
    end
  end

  def answer_evaluation
    # params[:question_id] == 0 is a 'test mode'
    if(params[:question_id].to_i != 0)
      @question = Question.find(params[:question_id])
      if(session[:evaluator_id] and @evaluator = User.find_by_id(session[:evaluator_id]) and @evaluator = @question.submitter)
        @evaluation_question = EvaluationQuestion.find(params[:evaluation_question_id])
        @evaluation_question.create_or_update_answers(user: @evaluator, question: @question, params: params)
        return render :json => {'success'=> true}.to_json, :status => :ok
      else
        # silent failure
        return render :json => {'success'=> false}.to_json, :status => :ok
      end
    else
      return render :json => {'success'=> true}.to_json, :status => :ok
    end
  end

  def thanks
    flash[:success] = "Thank you for your response and helping us make Ask an Expert better!"
    session[:evaluator_id] = nil
    return redirect_to(root_path)
  end

end
