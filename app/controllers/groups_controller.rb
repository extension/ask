# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class GroupsController < ApplicationController
  layout 'public'
  
  def show
    @group = Group.find(params[:id])
    @group_tags = @group.tags
    @open_questions = @group.open_questions.public_visible.find(:all, :limit => 10, :order => 'created_at DESC')
  end
  
  def ask
    @group = Group.find(params[:id])
    params[:fingerprint] = @group.widget_fingerprint
    @question = Question.new
    
    # display three image fields for question submitter
    3.times do
      @question.images.build
    end
    
    if(!session[:account_id].nil? && @submitter = User.find_by_id(session[:account_id]))      
      @email = @submitter.email
      @email_confirmation = @email
    end
    
    if request.post?
      @question = Question.new(params[:question])
      
      if !(@submitter = User.find_by_email(params[:question][:submitter_email]))
        @submitter = User.new({:email => params[:question][:submitter_email], :kind => 'PublicUser'})
      end
      
      @question.submitter = @submitter
      @question.assigned_group = @group
      @question.group_name = @group.name
      @question.user_ip = request.remote_ip
      @question.user_agent = request.env['HTTP_USER_AGENT']
      @question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
      @question.status = Question::SUBMITTED_TEXT
      @question.status_state = Question::STATUS_SUBMITTED
      
      if !@group.widget_public_option
        @question.is_private = true
        # in this case, the check box does not show for privacy for the submitter, everything that comes through this group is private,
        # so we default to the submitter marking private and this way, it cannot be overridden by an expert, when we don't know what 
        # the submitter wanted, we default to the safest thing, privacy by the submitter.
        @question.is_private_reason = Question::PRIVACY_REASON_SUBMITTER
      elsif params[:is_public].present? && params[:is_public] == '1'
        # For UX, the input label is the opposite of the flag. If the checkbox is checked, the question is public 
        @question.is_private = false
        @question.is_private_reason = Question::PRIVACY_REASON_PUBLIC
      else
        @question.is_private = true
        @question.is_private_reason = Question::PRIVACY_REASON_SUBMITTER
      end
      
      if @question.save
        session[:question_id] = @question.id
        session[:submitter_id] = @submitter.id
        redirect_to(@question, :notice => 'Question was successfully created.')
      end
    end
  end  
  
end