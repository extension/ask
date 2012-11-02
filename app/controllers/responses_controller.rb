class ResponsesController < ApplicationController
  
  def create
    if (session[:submitter_id].present?) && (params[:question_id].present?) && (submitter = User.find_by_id(session[:submitter_id])) && (question = Question.find_by_id(params[:question_id]))
      response = Response.new(params[:response])
      response.question = question
      response.submitter = submitter
      response.user_ip = request.remote_ip
      response.user_agent = (request.env['HTTP_USER_AGENT']) ? request.env['HTTP_USER_AGENT'] : ''
      response.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
      response.sent = true
      
      if !response.save
        flash[:notice] = "There was an error saving your response."
        return redirect_to submitter_view_url(:fingerprint => question.question_fingerprint)
      else
        flash[:notice] = "Your response has been saved, thanks!"
      end
      
      # handle reopening and reassigning of question if question has been closed/resolved and a response from the submitter is entered, otherwise, 
      # the status is submitted, so the expert has not responded to the response yet.
      if question.status_state != Question::STATUS_SUBMITTED
        question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED)
        QuestionEvent.log_public_response(question, submitter.id)
        QuestionEvent.log_reopen(question, question.assignee ? question.assignee : nil, User.system_user, Question::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT)
        question.assign_to(question.assignee, User.system_user, Question::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT, true, response)                  
      else
        QuestionEvent.log_public_response(question, submitter.id)
      end 
    else
      return record_not_found
    end
    
    redirect_to submitter_view_url(:fingerprint => question.question_fingerprint)
  end
  
  def remove_image
    if params[:image_id].present? && params[:id].present? && response = Response.find_by_id(params[:id])
      response.images.collect{|i| i.destroy if i.id == params[:image_id].to_i}
      flash[:notice] = "Image successfully deleted"
    else
      flash[:notice] = "Image does not exist"
    end
    redirect_to submitter_view_url(:fingerprint => response.question.question_fingerprint)
  end
end
