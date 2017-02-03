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

      # validate question
      if !response.valid?
        @argument_errors = ("We ran into a problem: " + response.errors.full_messages.join(' '))
        flash[:warning] = @argument_errors
        return redirect_to submitter_view_url(:fingerprint => question.question_fingerprint, :response => @response)
      end

      if !response.save
        flash[:notice] = "There was an error saving your response."
        return redirect_to submitter_view_url(:fingerprint => question.question_fingerprint)
      end

      # handle reopening and reassigning of question if question has been closed/resolved and a response from the submitter is entered, otherwise,
      # the status is submitted, so the expert has not responded to the response yet.
      if question.status_state != Question::STATUS_SUBMITTED
        question.update_attributes(:status => Question::STATUS_TEXT[Question::STATUS_SUBMITTED], :status_state => Question::STATUS_SUBMITTED)
        submitter_reopen = true
      else
        submitter_reopen = false
      end

      QuestionEvent.log_public_response(question, submitter.id)
      # away check, whether this is a reopen or not
      if(question.assignee.present? and question.assignee.away?)
        question.find_group_assignee_and_assign(assignment_comment: Question::PUBLIC_RESPONSE_REASSIGNMENT_BACKUP_COMMENT)
      elsif submitter_reopen
        question.assign_to(assignee: question.assignee,
                           assigned_by: User.system_user,
                           comment: Question::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT,
                           submitter_reopen: true,
                           submitter_comment: response.body)
        QuestionEvent.log_reopen(question, question.assignee, User.system_user, response.body)
      else
        # nothing else
      end
    else
      return record_not_found
    end

    flash[:notice] = "Your response has been saved, thanks!"
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
