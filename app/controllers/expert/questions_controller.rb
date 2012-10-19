# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::QuestionsController < ApplicationController
  require 'will_paginate/array' 
  
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def show
    @question = Question.find_by_id(params[:id])
    if @question.blank?
      flash[:error] = "Question not found."
      return redirect_to expert_home_url
    end
    @question_responses = @question.responses
    @last_question_response = @question.last_response
    @fake_related = Question.find(:all, :limit => 3, :offset => rand(Question.count))

    ga_tracking = []
    
    if @question.tags.length > 0
      ga_tracking = ["|tags"] + @question.tags.map(&:name)
    end
    
    question_resolves_with_resolver = @question.question_events.where('event_state = 2').includes(:initiator)
    
    if question_resolves_with_resolver.length > 0
      ga_tracking += ["|experts"] + question_resolves_with_resolver.map{|qe| qe.initiator.login}.uniq
    end
    
    if @question.assigned_group
      ga_tracking += ["|group"] + [@question.assigned_group.name]
    end
    
    if ga_tracking.length > 0
      flash.now[:googleanalytics] = expert_question_url(@question.id) + "?" + ga_tracking.join(",")
    end
  end
  
  def assign_options
    @user = User.find_by_id(params[:expert_id])
    @question = Question.find_by_id(params[:id])
  end
  
  def user_assign_options
    @question = Question.find_by_id(params[:id])
    user = User.find_by_id(params[:assignee_login])
    params[:assign_comment].present? ? assign_comment = params[:assign_comment] : assign_comment = nil
    @question.assign_to(user, current_user, assign_comment)
  end
  
  def assign
    if !params[:id]
      flash[:failure] = "You must select a question to assign."
      return redirect_to expert_home_url
    end
    
    @question = Question.find_by_id(params[:id])
        
    if !@question
      flash[:failure] = "Invalid question."
      return redirect_to expert_home_url
    end
    
    if !params[:assignee_login]
      flash[:failure] = "You must select a user or group to reassign."
      redirect_to expert_question_url(@question)
      return
    end
      
    user = User.where(:login => params[:assignee_login]).first
      
    if !user || user.retired?
      !user ? err_msg = "User does not exist." : err_msg = "User is retired from the system"
      flash[:failure] = err_msg
      return redirect_to expert_question_url(@question)
    end
      
    if user.away && current_user.id != user.id
      flash[:failure] = "This user has elected not to receive questions."
      return redirect_to expert_question_url(@question)  
    end
      
    params[:assign_comment].present? ? assign_comment = params[:assign_comment] : assign_comment = nil
        
    @question.assign_to(user, current_user, assign_comment)
    # re-open the question if it's reassigned after resolution
    if @question.status_state == Question::STATUS_RESOLVED || @question.status_state == Question::STATUS_NO_ANSWER
      @question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED)
      QuestionEvent.log_reopen(@question, user, current_user, assign_comment)
    end
    
    flash[:notice] = "Question successfully reassigned!"
    
    if params[:redirect_to_answer]
      return redirect_to answer_expert_question_url(@question)
    end
    redirect_to expert_question_url(@question)
  end
  
  def assign_to_group
    if !params[:id]
      flash[:failure] = "You must select a question to assign."
      return redirect_to expert_home_url
    end
    
    @question = Question.find_by_id(params[:id])
        
    if !@question
      flash[:failure] = "Invalid question."
      return redirect_to expert_home_url
    end
    
    if !params[:group_id]
      flash[:failure] = "You must select a user or group to reassign."
      redirect_to expert_question_url(@question)
      return
    end
      
    group = Group.find_by_id(params[:group_id])
      
    if !group
      flash[:failure] = "Group does not exist."
      return redirect_to expert_question_url(@question)
    end
      
    params[:assign_comment].present? ? assign_comment = params[:assign_comment] : assign_comment = nil
        
    @question.assign_to_group(group, current_user, assign_comment)
    # re-open the question if it's reassigned after resolution
    if @question.status_state == Question::STATUS_RESOLVED || @question.status_state == Question::STATUS_NO_ANSWER
      @question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED)
      QuestionEvent.log_reopen_to_group(@question, group, current_user, assign_comment)
    end
    
    flash[:notice] = "Question successfully reassigned!"
    
    if params[:redirect_to_answer]
      return redirect_to answer_expert_question_url(@question)
    end
    redirect_to expert_question_url(@question)
  end
  
  # show the expert form to answer a question
  def answer
    @question = Question.where(:id => params[:id]).first
    
    if !@question
      flash[:failure] = "Invalid question."
      return redirect_to expert_question_url(@question)
    end
    
    if @question.resolved?
      flash[:failure] = "This question has already been resolved.<br />It could have been resolved while you were working on it.<br />We appreciate your help in resolving these questions!"
      return redirect_to expert_question_url(@question)
    end
    
    @status = params[:status_state]
    
    # if expert chose a Question to answer this with, find that so that we can 
    # attach that to the question as a contributing question.
    # UPDATE: we're not going to be using related questions for the time being, but will leave this for now in case 
    # we add it back in the future.
    @related_question = Question.find_by_id(params[:related_question]) if params[:related_question].present?
  
    @sampletext = params[:sample] if params[:sample]
    current_user.signature.present? ? @signature = current_user.signature : @signature = "-#{current_user.public_name}"
    
    if request.post?
      answer = params[:current_response]
      (params[:signature] and params[:signature].strip != '') ? @signature = params[:signature] : @signature = ''
      
      if answer.blank? 
        flash[:failure] = "You must not leave the answer blank."
        return
      end
      
      @related_question ? contributing_question = @related_question : contributing_question = nil
      (@status and @status.to_i == Question::STATUS_NO_ANSWER) ? q_status = Question::STATUS_NO_ANSWER : q_status = Question::STATUS_RESOLVED
      
      @question.add_resolution(q_status, current_user, answer, @signature, contributing_question)   
      
      # TODO: Add new notification logic here.
      #Notification.create(:notifytype => Notification::AAE_PUBLIC_EXPERT_RESPONSE, :account => User.systemuser, :creator => @currentuser, :additionaldata => {:submitted_question_id => @submitted_question.id, :signature => @signature })  	    
      flash[:success] = "Thanks for answering this question."
      redirect_to expert_question_url(@question)
    end
  end
  
  def assign_to_wrangler
    if params[:id].present? && question = Question.find_by_id(params[:id]) 
      recipient = question.assign_to_question_wrangler(current_user)
      # re-open the question if it's reassigned after resolution
      if question.status_state == Question::STATUS_RESOLVED || question.status_state == Question::STATUS_NO_ANSWER
        question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED)
        QuestionEvent.log_reopen(question, recipient, current_user, Question::WRANGLER_REASSIGN_COMMENT)
      end  
    else
      flash[:error] = "Question specified does not exist."
      return redirect_to expert_home_url
    end
    
    flash[:notice] = "Question successfully assigned to a question wrangler!"
    redirect_to expert_question_url(question)
  end
  
  def reject
    if params[:id].present? && @question = Question.find_by_id(params[:id])
      if @question.resolved?
        flash[:failure] = "This question has already been resolved."
        return redirect_to expert_question_url(@question)
      end
      
      if request.post?
        if (message = params[:reject_message]).present?
          @question.add_resolution(Question::STATUS_REJECTED, current_user, message)
          flash[:success] = "The question has been rejected."
          redirect_to expert_question_url(@question)    
        else
          flash.now[:failure] = "Please document a reason for rejecting this question"
          render nil
          return
        end
      end
    else
      flash[:failure] = "Question specified does not exist."
      redirect_to expert_home_url
    end
  end
  
  def report_spam
    question = Question.find_by_id(params[:id])
    if question.blank?
      flash[:failure] = "Question specified does not exist."
      return redirect_to expert_home_url
    end
      
    question.update_attributes(:spam => true, :is_private => true, :is_private_reason => Question::PRIVACY_REASON_SPAM)
    QuestionEvent.log_spam(question, current_user)       
        
    flash[:success] = "Incoming question has been successfully marked as spam."
    redirect_to expert_home_url
  end
  
  def report_ham
    question = Question.find_by_id(params[:id])
    if question.blank?
      flash[:failure] = "Question specified does not exist."
      return redirect_to expert_home_url
    end
    
    # we don't know at this point whether the submitter marked it as public or private originally before it was marked as spam, so 
    # we do the safe thing here and mark it as private by the submitter.  
    question.update_attributes(:spam => false, :is_private => true, :is_private_reason => Question::PRIVACY_REASON_SUBMITTER)
    QuestionEvent.log_ham(question, current_user)       
        
    flash[:success] = "Incoming question has been successfully marked as not spam."
    redirect_to expert_question_url(question)
  end
  
  def close_out
    @question = Question.find_by_id(params[:id])
    @submitter_name = @question.submitter_name
    
    if request.post?
      close_out_reason = params[:close_out_reason]
      
      if !@question
        flash.now[:failure] = 'Question not found'
        return render nil
      end
      
      if close_out_reason.blank?
        flash.now[:failure] = 'Please document a reason for closing this question.'
        return render nil
      end
          
      # get the last response type, if a non-answer response was previously sent, respect the status of it in the question, else 
      # set it to resolved
      if last_response = @question.last_response
        resolver = last_response.initiator
        if last_response.event_state == QuestionEvent::NO_ANSWER
          @question.update_attributes(:status => Question::NO_ANSWER_TEXT, 
                                      :status_state => Question::STATUS_NO_ANSWER,
                                      :current_resolver => resolver,
                                      :resolved_at => last_response.created_at,
                                      :current_response => last_response.response,
                                      :current_resolver_email => resolver.email)
        else    
          @question.update_attributes(:status => Question::RESOLVED_TEXT, 
                                      :status_state => Question::STATUS_RESOLVED,
                                      :current_resolver => resolver,
                                      :resolved_at => last_response.created_at,
                                      :current_response => last_response.response,
                                      :current_resolver_email => resolver.email)
        end
      # else, we're closing it out with no response, which is not supposed to happen
      # close out is only being used for questions with a response now, for purposes like
      # when someone responds with a thank you and you need to close it out without a response.
      else           
        flash[:error] = "Please either reassign, answer or reject the question." 
        return redirect_to expert_question_url(@question)
      end                                    
      
      QuestionEvent.log_close(@question, current_user, close_out_reason)                                                      
      flash[:success] = "Question closed successfully!"
      redirect_to expert_question_url(@question)
    end
  end
    
  def reactivate
    question = Question.find_by_id(params[:id])
    question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED, :current_resolver => nil, :current_response => nil, :resolved_at => nil, :current_resolver_email => nil)
    QuestionEvent.log_reactivate(question, current_user)
    flash[:success] = "Question re-activated"
    redirect_to expert_question_url(question)
  end  
    
  def add_tag
    @question = Question.find_by_id(params[:id])
    @tag = @question.set_tag(params[:tag])
    if @tag == false
      render :nothing => true
    end
  end
  
  def remove_tag
    @question = Question.find_by_id(params[:id])
    tag = Tag.find(params[:tag_id])
    @question.tags.delete(tag)
  end
  
  def reassign
    @question = Question.find_by_id(params[:id])
    per_page = 10
    @experts = Array.new
    @question.location_id.present? ? location_experts = User.with_expertise_location(@question.location_id) : location_experts = []
    @question.county_id.present? ? county_experts = User.with_expertise_county(@question.county_id) : county_experts = []
    question_tags = @question.tags.map{|t| "'#{t.name}'"}.join(',')
      
    if question_tags.present?
      if @question.county_id?
        expert_ids = county_experts.map(&:id)
        @experts.concat(User.tagged_with_any(question_tags).where("users.id IN (#{expert_ids.join(',')})")) if expert_ids.length > 0
      end      
    
      if @question.location_id?
        expert_ids = location_experts.map(&:id)
        @experts.concat(User.tagged_with_any(question_tags).where("users.id IN (#{expert_ids.join(',')})")) if expert_ids.length > 0
      end
    
      @experts.concat(User.tagged_with_any(question_tags))
    end
    
    @experts.concat(county_experts) if county_experts.length > 0
    @experts.concat(location_experts) if location_experts.length > 0
    @experts.uniq!
    
    @expert_results = @experts.paginate({:page => params[:page], :per_page => per_page})
  end
  
  def associate_with_group
    @question = Question.find_by_id(params[:id])
    @group = Group.find_by_id(params[:group_id])
    
    @question.assigned_group = @group 
    @question.save
  end
  
end
