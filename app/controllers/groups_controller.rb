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
    
   
    if request.post?
      @question = Question.new(params[:question])
      
      if current_user and current_user.email.present?
        @submitter = current_user
      else
        if !(@submitter = User.find_by_email(params[:question][:submitter_email]))
          @submitter = User.new({:email => params[:question][:submitter_email], :kind => 'PublicUser'})
          if !@submitter.valid?
            # TODO: to be sure there's a better way to combine errors?
            @submitter.errors.each do |attribute,message|
              # message could be an array, but not going to be for User
              @question.errors[attribute] = message
            end
            return
          end
        end
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
        if(!@question.spam?)
          session[:question_id] = @question.id
          session[:submitter_id] = @submitter.id
          redirect_to(@question, :notice => 'Question was successfully created.')
        else
          redirect_to(root_url)
        end
      end
    end
  end

  # convenience method to redirect to a widget page for the group
  def widget
    @group = Group.find(params[:id])
    return redirect_to group_widget_url(fingerprint: @group.widget_fingerprint)
  end  
  
end