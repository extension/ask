# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class EvaluationController < ApplicationController
  before_filter :set_evaluator, except: [:view,:authorize]

  def view
    @question = Question.find_by_question_fingerprint(params[:fingerprint])
    # the hash will authenticate the question submitter to edit their question.
    if @question.present?
      if(session[:submitter_id].present? and (session[:submitter_id].to_i == @question.submitter_id))
        return redirect_to(evaluation_form_url(@question))
      else
        return render(template: 'evaluation/email_prompt')
      end
    else
      return record_not_found
    end
  end
  
  def authorize
    @question = Question.find_by_question_fingerprint(params[:fingerprint])

    return record_not_found if !@question

    if params[:email_address].present? and (submitter = User.find_by_email(params[:email_address].strip.downcase)) 
      # make sure that this question belongs to this user
      if(@question.submitter.id == submitter.id)
        session[:submitter_id] = submitter.id
        return redirect_to(evaluation_form_url(@question))
      end
    end

    flash.now[:warning] = "The email address you entered does not match the email used to submit the question. Please check the email address and try again."
    return render(template: 'evaluation/email_prompt')
  end



  def question
    @page_title = 'Evaluation Questions'
    @question = Question.find(params[:id])
    # set the question id so they can view their question
    session[:question_id] = @question.id
    if(@evaluator != @question.submitter)
      return render(template: 'evaluation/private')
    end
  end

  def example
    @question = Question.last
    @page_title = 'Example Evaluation Questions'
    @question_testing = true
    return render(template: 'evaluation/question')
  end

  def answer_demographic
    @demographic_question = DemographicQuestion.find(params[:demographic_question_id])
    @demographic_question.create_or_update_answers(user: @evaluator, params: params)
    return render :json => {'success'=> true}.to_json, :status => :ok
  end

  def answer_evaluation
    # params[:question_id] is a 'test mode'
    if(params[:question_id].to_i != 0)
      @question = Question.find(params[:question_id])
      @evaluation_question = EvaluationQuestion.find(params[:evaluation_question_id])
      @evaluation_question.create_or_update_answers(user: @evaluator, question: @question, params: params)
    end
    return render :json => {'success'=> true}.to_json, :status => :ok
  end

  def thanks
    flash[:success] = "Thank you for your response and helping us make Ask an Expert better!"
    return redirect_to(root_path)
  end

  private

  def set_evaluator
    if(current_user)
      @evaluator = current_user
    elsif(session[:submitter_id])
      @evaluator = User.find_by_id(session[:submitter_id])
    end
    return redirect_to(root_path) if @evaluator.nil?
  end

end