# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::QuestionsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def show
    @question = Question.find_by_id(params[:id])
    @question_responses = @question.responses
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
      flash[:failure] = "You must select a user to reassign."
      redirect_to expert_question_url(@question)
      return
    end
      
    user = User.where(:login => params[:assignee_login]).first
      
    if !user || user.retired?
      !user ? err_msg = "User does not exist." : err_msg = "User is retired from the system"
      flash[:failure] = err_msg
      return redirect_to expert_question_url(@question)
    end
      
    if !user.aae_responder && current_user.id != user.id
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
    # attach that to the question as a contributing question
    @related_question = Question.find_by_id(params[:related_question]) if params[:related_question].present?
  
    @sampletext = params[:sample] if params[:sample]
    signature_pref = current_user.user_preferences.find_by_name('signature')
    signature_pref ? @signature = signature_pref.setting : @signature = "-#{current_user.name}"
    
    if request.post?
      answer = params[:current_response]
      (params[:signature] and params[:signature].strip != '') ? @signature = params[:signature] : @signature = ''
      
      if !answer or '' == answer.strip 
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
    @location_experts = ''
    @county_experts = ''
    @tag_experts = ''
    @tag_and_county_experts = ''
    @tag_and_location_experts = ''
    
    if @question.location_id?
      @location_experts = User.with_expertise_location(@question.location_id).limit(6)
    end
    
    if @question.county_id?
      @county_experts = User.with_expertise_county(@question.county_id).limit(6)
    end
    
    if @question.tags.length > 0
      @tag_experts = User.tagged_with(@question.tags.first.id).limit(6)
      if @question.county_id?
        @tag_and_county_experts = User.with_expertise_county(@question.county_id).tagged_with(@question.tags.first.id).limit(6)
      end
      if @question.location_id?
        @tag_and_location_experts = User.with_expertise_location(@question.location_id).tagged_with(@question.tags.first.id).limit(6).offset(rand(6))
      end
    end
    # tags_names = ["horses", "horticulture"]
    # @tag_experts = User.joins{tags}.where{tags.name.in tags_names}.group{User.id}.having("count(User.id) = #{tags_names.size}")
  end
  
end
