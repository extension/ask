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
    if @question.blank?
      flash[:error] = "Question not found."
      return redirect_to expert_home_url
    end
    @question_responses = @question.responses
    @last_question_response = @question.last_response
    @original_group = @question.original_group
    
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
      flash.now[:googleanalytics] = expert_question_path(@question.id) + "?" + ga_tracking.join(",")
    end
  end
  
  def submitted
    @user = User.find_by_id(params[:id])
    @question_list = "submitted"
    @questions = @user.submitted_questions.page(params[:page]).order('created_at DESC')
    @question_count = @user.submitted_questions.length
  end
  
  def assign_options
    @user = User.find_by_id(params[:expert_id])
    @question = Question.find_by_id(params[:id])
    
    if !@question.present?
      flash[:error] = "Question does not exist with this ID."
      return redirect_to expert_home_url
    end
    
    if !@user.present?
      flash[:error] = "Expert does not exist with this ID."
      return redirect_to expert_question_url(@question)
    end
  end
  
  def group_assign_options
    @group = Group.find_by_id(params[:group_id])
    @question = Question.find_by_id(params[:id])  
  end
  
  def change_location
    @question = Question.find_by_id(params[:id])
    change_hash = Hash.new
    save_location = false
    
    change_hash[:changed_county] = { :old => @question.county.present? ? @question.county.name : '', :new => ''}
    change_hash[:changed_location] = { :old => @question.location.present? ? @question.location.name : '', :new => ''}
    
    if params[:location_id].present?
      location = Location.find_by_id(params[:location_id])
      change_hash[:changed_location] = { :old => @question.location.present? ? @question.location.name : '', :new => location.name }
      # do nothing here if the location did not change
      if location != @question.location
        @question.location = location
        @question.county = nil
        save_location = true
      end
    # location id cleared out
    else
      if @question.location.present?
        @question.location = nil  
        @question.county = nil
        save_location = true
      end
    end
    
    if params[:county_id].present? && params[:location_id].present?
      county = County.find_by_id(params[:county_id])
      change_hash[:changed_county] = { :old => @question.county.present? ? @question.county.name : '', :new => county.name }
      # do nothing here if county did not change (probably shouldn't happen but going to cover this case anyways)
      if county != @question.county
        @question.county = county
        save_location = true
      end
    # county_id cleared out
    else
      if @question.county.present?
        @question.county = nil
        save_location = true
      end
    end
    
    if save_location
      @question.save
      QuestionEvent.log_location_change(@question, current_user, change_hash)
    end
  end
  
  def make_private
    @question = Question.find_by_id(params[:id])
    @question.is_private = true
    @question.is_private_reason = Question::PRIVACY_REASON_EXPERT
    @question.save
  end
  
  def make_public
    @question = Question.find_by_id(params[:id])
    @question.is_private = false
    @question.is_private_reason = Question::PRIVACY_REASON_PUBLIC
    @question.save
  end
  
  def assign
    if !params[:id]
      flash[:error] = "You must select a question to assign."
      return redirect_to expert_home_url
    end
    
    @question = Question.find_by_id(params[:id])
        
    if !@question
      flash[:error] = "Invalid question."
      return redirect_to expert_home_url
    end
    
    if !params[:assignee_id]
      flash[:error] = "You must select a user or group to reassign."
      redirect_to expert_question_url(@question)
      return
    end
      
    user = User.find_by_id(params[:assignee_id])
      
    if !user || user.retired?
      !user ? err_msg = "User does not exist." : err_msg = "User is retired from the system"
      flash[:error] = err_msg
      return redirect_to expert_question_url(@question)
    end
      
    if user.away && current_user.id != user.id
      flash[:error] = "This user has elected not to receive questions."
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
      flash[:error] = "You must select a question to assign."
      return redirect_to expert_home_url
    end
    
    @question = Question.find_by_id(params[:id])
        
    if !@question
      flash[:error] = "Invalid question."
      return redirect_to expert_home_url
    end
    
    if !params[:group_id]
      flash[:error] = "You must select a user or group to reassign."
      redirect_to expert_question_url(@question)
      return
    end
      
    group = Group.find_by_id(params[:group_id])
      
    if !group
      flash[:error] = "Group does not exist."
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
    @question = Question.find_by_id(params[:id])
    
    if !@question
      flash[:error] = "Invalid question."
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
    @image_count = 3
    
    if @question.resolved?
      if request.get?
        flash[:error] = "Someone has already resolved this question.<br />Please view the response before sending another."
        return redirect_to expert_question_url(@question)
      elsif request.post?
        flash[:error] = "Someone has already resolved this question.<br />Please view the response before sending another."
        @answer = params[:current_response]
        return render nil
      end
    end
    
    if request.post?
      answer = params[:current_response]
      (params[:signature] and params[:signature].strip != '') ? @signature = params[:signature] : @signature = ''
      
      if answer.blank? 
        flash[:error] = "The answer is blank. Please add an answer and submit again."
        return
      end
      
      if (current_user != @question.assignee)
        @question.assign_to(current_user, current_user, nil)
      end
      
      @related_question ? contributing_question = @related_question : contributing_question = nil
      (@status and @status.to_i == Question::STATUS_NO_ANSWER) ? q_status = Question::STATUS_NO_ANSWER : q_status = Question::STATUS_RESOLVED
      
      begin
        @question.add_resolution(q_status, current_user, answer, @signature, contributing_question, params[:response])
      rescue Exception => e
        @answer = answer
        flash[:error] = "Error: #{e}"
        return render nil
      end
      
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
        flash[:error] = "This question has already been resolved."
        return redirect_to expert_question_url(@question)
      end
      
      if request.post?
        if (message = params[:reject_message]).present?
          @question.add_resolution(Question::STATUS_REJECTED, current_user, message)
          flash[:success] = "The question has been rejected."
          redirect_to expert_question_url(@question)    
        else
          flash.now[:error] = "Please document a reason for rejecting this question"
          render nil
          return
        end
      end
    else
      flash[:error] = "Question specified does not exist."
      redirect_to expert_home_url
    end
  end
  
  def close_out
    @question = Question.find_by_id(params[:id])
    @submitter_name = @question.submitter_name
    
    if request.post?
      close_out_reason = params[:close_out_reason]
      
      if !@question
        flash.now[:error] = 'Question not found'
        return render nil
      end
      
      if close_out_reason.blank?
        flash.now[:error] = 'Please document a reason for closing this question.'
        return render nil
      end
          
      # get the last response type, if a non-answer response was previously sent, respect the status of it in the question, else 
      # set it to resolved
      # UPDATE: NOW, EXPERTS CAN CLOSE OUT A QUESTION WITHOUT AN EXPERT RESPONSE.
      if last_response = @question.last_response
        resolver = last_response.initiator
        if last_response.event_state == QuestionEvent::NO_ANSWER
          @question.update_attributes(:status => Question::NO_ANSWER_TEXT, 
                                      :status_state => Question::STATUS_NO_ANSWER,
                                      :current_resolver => resolver,
                                      :resolved_at => last_response.created_at,
                                      :current_response => last_response.response)
        else    
          @question.update_attributes(:status => Question::RESOLVED_TEXT, 
                                      :status_state => Question::STATUS_RESOLVED,
                                      :current_resolver => resolver,
                                      :resolved_at => last_response.created_at,
                                      :current_response => last_response.response)
        end
      # IF NO EXPERT RESPONSE YET...
      else
        @question.update_attributes(:status => Question::CLOSED_TEXT, 
                                    :status_state => Question::STATUS_CLOSED,
                                    :current_resolver => current_user,
                                    :resolved_at => Time.now,
                                    :current_response => close_out_reason)
      end                                    
      
      QuestionEvent.log_close(@question, current_user, close_out_reason)                                                      
      flash[:success] = "Question closed successfully!"
      redirect_to expert_question_url(@question)
    end
  end
    
  def reactivate
    question = Question.find_by_id(params[:id])
    question.update_attributes(:status => Question::SUBMITTED_TEXT, :status_state => Question::STATUS_SUBMITTED, :current_resolver_id => nil, :current_response => nil, :resolved_at => nil)
    QuestionEvent.log_reactivate(question, current_user)
    flash[:success] = "Question re-activated"
    redirect_to expert_question_url(question)
  end  
  
  def add_history_comment
    @question = Question.find_by_id(params[:id])
    if params[:history_comment].present?
      @question.add_history_comment(current_user, params[:history_comment])
    end
    redirect_to expert_question_url(@question)
  end
    
  def add_tag
    @question = Question.find_by_id(params[:id])
    @previous_tags = @question.tags.collect{|t| t.name}.join(', ')
    @tag = @question.set_tag(params[:tag])
    @current_tags = @question.tags.collect{|t| t.name}.join(', ')
    QuestionEvent.log_tag_change(@question, current_user, @current_tags, @previous_tags) if @previous_tags != @current_tags
    if @tag == false
      render :nothing => true
    end
  end
  
  def remove_tag
    @question = Question.find_by_id(params[:id])
    @previous_tags = @question.tags.collect{|t| t.name}.join(', ')
    tag = Tag.find(params[:tag_id])
    @question.tags.delete(tag)
    @current_tags = @question.tags.collect{|t| t.name}.join(', ')
    QuestionEvent.log_tag_change(@question, current_user, @current_tags, @previous_tags) if @previous_tags != @current_tags
  end
  
  
  def update_reassign_results
    @question = Question.find_by_id(params[:id])
    @experts = Array.new
    @groups = Array.new
    @filter_terms = Array.new
    
    if params[:location_id].present? 
      @question.location_id = params[:location_id]
    end
    
    if params[:county_id].present? 
      @question.county_id = params[:county_id]
    else
      @question.county_id = ""
    end
    
    if @question.location_id.present? 
      # @filter_terms <<  @question.location.name
      location_experts = User.active.with_expertise_location(@question.location_id)
      location_groups = Group.assignable.with_expertise_location(@question.location_id)
    else
      location_experts = []
      location_groups = []
    end
      
    if @question.county_id.present?
      # @filter_terms <<  @question.county.name
      county_experts = User.active.with_expertise_county(@question.county_id) 
      county_groups = Group.assignable.with_expertise_county(@question.county_id) 
    else
      county_experts = []
      county_groups = []
    end
    
    question_tags_array = @question.tags.all
    
    @question.tags.each do |tag|
      @filter_terms <<  tag.name
    end
      
    if question_tags_array.present?
      if @question.county_id?
        expert_ids = county_experts.map(&:id)
        @experts.concat(User.active.tagged_with_any(question_tags_array).where("users.id IN (#{expert_ids.join(',')})")) if expert_ids.length > 0
        
        group_ids = county_groups.map(&:id)
        @groups.concat(Group.assignable.tagged_with_any(question_tags_array).where("groups.id IN (#{group_ids.join(',')})")) if group_ids.length > 0
      end      
    
      if @question.location_id?
        expert_ids = location_experts.map(&:id)
        @experts.concat(User.active.tagged_with_any(question_tags_array).where("users.id IN (#{expert_ids.join(',')})")) if expert_ids.length > 0
        
        group_ids = location_groups.map(&:id)
        @groups.concat(Group.assignable.tagged_with_any(question_tags_array).where("groups.id IN (#{group_ids.join(',')})")) if group_ids.length > 0
      end
    
      @experts.concat(User.active.tagged_with_any(question_tags_array))
      @groups.concat(Group.assignable.tagged_with_any(question_tags_array))
    end
    
    if county_experts.length > 0
       @experts.concat(county_experts)
       @groups.concat(county_groups)
    end  
      
    if location_experts.length > 0
      @experts.concat(location_experts)  
      @groups.concat(location_groups)  
    end
    
    @experts.uniq!
    @groups.uniq!
    
    @experts = @experts.first(8)
    @groups = @groups.first(3)
    
    @filter_terms_count = @filter_terms.count + 2 #for location and county
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @experts.map(&:id)})
  end
  
  def reassign
    @question = Question.find_by_id(params[:id])
    @experts = Array.new
    @groups = Array.new
    @filter_terms = Array.new
    location_experts = Array.new
    location_groups = Array.new
    county_experts = Array.new
    county_groups = Array.new
    location_experts_backup = Array.new
    location_groups_backup = Array.new
    route_from_anywhere_experts = Array.new
    route_from_anywhere_groups = Array.new
    
    
    if @question.county_id.present?
      county_experts = User.active.with_expertise_county(@question.county_id) 
      county_groups = Group.assignable.with_expertise_county(@question.county_id) 
    end
    
    if @question.location_id.present? 
      location_experts = User.active.with_expertise_location_all_counties(@question.location_id)
      location_groups = Group.assignable.with_expertise_location_all_counties(@question.location_id)
      
      # we'll also go ahead and add on the experts and groups from the state that say they'll take questions from anywhere as a backup
      location_experts_backup = User.active.route_from_anywhere.with_expertise_location(@question.location_id)
      location_groups_backup = Group.assignable.route_outside_locations.with_expertise_location(@question.location_id)
    end
    
    # if the experts for a location are empty or no location listed, then pull those experts who will receive questions from anywhere, 
    # if the groups for a location are empty or no location listed, then pull groups who will receive questions outside their locations
    if location_experts.count == 0 && location_experts_backup.count == 0
      route_from_anywhere_experts = User.active.route_from_anywhere
    end
    if location_groups.count == 0 && location_groups_backup.count == 0
      route_from_anywhere_groups = Group.assignable.route_outside_locations
    end
    
    question_tags_array = @question.tags.all
    
    @question.tags.each do |tag|
      @filter_terms <<  tag.name
    end
      
    if question_tags_array.present?
      if county_experts.count > 0
        expert_ids = county_experts.map(&:id)
        @experts.concat(User.active.tagged_with_any(question_tags_array).where("users.id IN (#{expert_ids.join(',')})")) 
      end
      
      if county_groups.count > 0  
        group_ids = county_groups.map(&:id)
        @groups.concat(Group.assignable.tagged_with_any(question_tags_array).where("groups.id IN (#{group_ids.join(',')})")) 
      end      
    
      if location_experts.count > 0
        expert_ids = location_experts.map(&:id)
        @experts.concat(User.active.tagged_with_any(question_tags_array).where("users.id IN (#{expert_ids.join(',')})")) 
      end
      
      if location_experts_backup.count > 0
        expert_ids = location_experts_backup.map(&:id)
        @experts.concat(User.active.tagged_with_any(question_tags_array).where("users.id IN (#{expert_ids.join(',')})"))
      end
      
      if location_groups.count > 0
        group_ids = location_groups.map(&:id)
        @groups.concat(Group.assignable.tagged_with_any(question_tags_array).where("groups.id IN (#{group_ids.join(',')})")) 
      end
      
      if location_groups_backup.count > 0
        group_ids = location_groups_backup.map(&:id)
        @groups.concat(Group.assignable.tagged_with_any(question_tags_array).where("groups.id IN (#{group_ids.join(',')})"))
      end
    
      # after the list of groups and experts are populated with those matching tag and location, just list those experts and groups that match the tags that take questions from anywhere.
      if route_from_anywhere_experts.count > 0
        expert_ids = route_from_anywhere_experts.map(&:id)
        @experts.concat(User.active.tagged_with_any(question_tags_array).where("users.id IN (#{expert_ids.join(',')})"))
      end
      
      if route_from_anywhere_groups.count > 0
        group_ids = route_from_anywhere_groups.map(&:id)
        @groups.concat(Group.assignable.tagged_with_any(question_tags_array).where("groups.id IN (#{group_ids.join(',')})"))
      end
    end
    
    # we have the tag and location best matches above, now further down the list, we'll list just the best locational matches
    @experts.concat(county_experts) if county_experts.length > 0
    @groups.concat(county_groups) if county_groups.length > 0  
    @experts.concat(location_experts) if location_experts.length > 0   
    @groups.concat(location_groups)  if location_groups.length > 0
    @experts.concat(location_experts_backup) if location_experts_backup.length > 0
    @groups.concat(location_groups_backup) if location_groups_backup.length > 0
    
    @experts.uniq!
    @groups.uniq!
    
    @experts = @experts.first(20)
    @groups = @groups.first(3)
    
    @filter_terms_count = @filter_terms.count + 2 #for location and county
    @handling_rates = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @experts.map(&:id)})
  end
  
  
  def associate_with_group
    @question = Question.find_by_id(params[:id])
    @group = Group.find_by_id(params[:group_id])
    if(@question and @group)
      @question.change_group(@group,current_user)
    end
  end
  
  def activity_notificationprefs
    user = current_user
    if params[:question].present? and params[:value].present?
      if params[:value] == '1'
      Preference.create_or_update(user, Preference::NOTIFICATION_ACTIVITY, true, nil, params[:question])
      end
      if params[:value] == '0'
      Preference.create_or_update(user, Preference::NOTIFICATION_ACTIVITY, false, nil, params[:question])
      end
    end
    redirect_to :back
  end
  
end
