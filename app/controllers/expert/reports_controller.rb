# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::ReportsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  def index
    @locations = Location.order('fipsid ASC')
    @my_tags = current_user.tags
    @condition_array = ""
    @experts = ""
    
    if(params[:year_month])
      @date = Date.strptime(params[:year_month] + "-01")
      @year_month = params[:year_month]
      @previous_year_month = (@date - 1.month).strftime('%Y-%m')
      if User.year_month_string(Date.today.year,Date.today.month) != @year_month
        @following_year_month = (@date + 1.month).strftime('%Y-%m')
      end
    elsif(params[:year])
      return record_not_found if params[:year].to_i == 0
      @year_month = params[:year].to_i
      @date = params[:year].strip
    else
      @date = DateTime.now
      @year_month = User.year_month_string(Date.today.year,Date.today.month)
      @previous_year_month = (DateTime.now - 1.month).strftime('%Y-%m')
    end
    
    @my_groups = Array.new
      current_user.group_memberships.each do |membership|
      @my_groups << membership
    end
    
    if params[:group_id].present?
      @group = Group.find_by_id(params[:group_id])
      return record_not_found if !@group.present?
      @my_groups << @group
      @my_groups = @my_groups.uniq
      
      question_group_scope = Question.from_group(@group.id)
      expert_group_scope = User.group_membership_for(@group.id)
    else
      question_group_scope = Question.where({})
      expert_group_scope = User.where({})
    end
    
    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      return record_not_found if !@location.present?
      @condition_array = " #{@location.name} "
      question_location_scope = question_group_scope.by_location(@location)
      expert_location_scope = expert_group_scope.from_location(@location)
      
      ### execute these things while we are in the location specified block (county existence doesn't matter)
      
      # get number of questions resolved by experts in state
      @resolved_by_state_experts = question_location_scope.not_rejected.resolved_questions_by_in_state_responders(@location, @year_month).count
      # get number of responses by experts in state
      responses_by_state_experts = question_location_scope.not_rejected.responses_by_in_state_responders(@location, @year_month)    
      @responses_by_in_state_count = responses_by_state_experts.count
      @responders_in_state_count = responses_by_state_experts.map{|r| r.initiated_by_id}.uniq.count
        
      # get number of questions resolved by experts out of state
      @resolved_by_outside_state_experts = question_location_scope.not_rejected.resolved_questions_by_outside_state_responders(@location, @year_month).count
      # get number of responses by experts out of state for questions from this state
      responses_by_outside_state_experts = question_location_scope.not_rejected.responses_by_outside_state_responders(@location, @year_month)
      @responses_by_outside_state_count = responses_by_outside_state_experts.count
      @responders_outside_state_count = responses_by_outside_state_experts.map{|r| r.initiated_by_id}.uniq.count
      
      ###
      
      if params[:county_id].present?
        @county = County.find_by_id(params[:county_id])
        return record_not_found if !@county.present?
        @condition_array = " #{@county.name}, #{@location.name} "
        question_location_scope = question_group_scope.by_county(@county)
        expert_location_scope = expert_group_scope.from_county(@county)  
      end
    # else no location specified
    else
      question_location_scope = question_group_scope
      expert_location_scope = expert_group_scope
    end
    
    @experts = expert_location_scope.by_question_event_count(QuestionEvent::RESOLVED, {limit: 40, yearmonth: @year_month})
    @unanswered_questions_count = question_location_scope.submitted.not_rejected.order('created_at DESC').count
    @questions_asked = question_location_scope.not_rejected.asked_list_for_year_month(@year_month).order('created_at DESC')
    @questions_answered = question_location_scope.not_rejected.answered_list_for_year_month(@year_month).order('created_at DESC')
      
    # get number of responses for questions
    responses = question_location_scope.not_rejected.resolved_response_list_for_year_month(@year_month)
    @response_count = responses.count
    @responder_count = responses.map{|r| r.initiated_by_id}.uniq.count
           
    @condition_array += " #{@group.name} " if defined?(@group) && @group.present?
  end
  
  def expert
    @expert = User.find(params[:id])
    
    if(!@earliest_assigned_at = @expert.earliest_assigned_at)
      return
    end
    year_months = User.year_months_between_dates(@earliest_assigned_at,Time.now)

    assigned_count_by_year_month = @expert.assigned_count_by_year_month
    answered_count_by_year_month = @expert.answered_count_by_year_month

    assigned_count_by_year = @expert.assigned_count_by_year_month
    answered_count_by_year = @expert.answered_count_by_year_month

    @counts_by_year_and_year_month = {}
    year_months.each do |year_month|
      year = year_month.split('-')[0]
      @counts_by_year_and_year_month[year] ||= {}
      @counts_by_year_and_year_month[year][year_month] = {}
      @counts_by_year_and_year_month[year][year_month]['assigned'] = (assigned_count_by_year_month[year_month] ? assigned_count_by_year_month[year_month] : 0)
      @counts_by_year_and_year_month[year][year_month]['answered'] = (answered_count_by_year_month[year_month] ? answered_count_by_year_month[year_month] : 0)
    end

    @counts_by_year = {}
    assigned_count_by_year = @expert.assigned_count_by_year
    answered_count_by_year = @expert.answered_count_by_year
    @counts_by_year_and_year_month.keys.each do |year|
      year_int = year.to_i
      @counts_by_year[year] = {} 
      @counts_by_year[year]['assigned'] = (assigned_count_by_year[year_int] ? assigned_count_by_year[year_int] : 0)
      @counts_by_year[year]['answered'] = (answered_count_by_year[year_int] ? answered_count_by_year[year_int] : 0)
    end
  end
  
  def question_list
    @condition_string = ""
    filter = params[:filter] 
    filter = 'answered' if filter.blank?
    
    if(params[:year_month])
      @year_month = params[:year_month]
    elsif(params[:year])
      return record_not_found if params[:year].to_i == 0
      @year_month = params[:year]
    else
      @year_month = User.year_month_string(Date.today.year,Date.today.month)
    end
    
    if params[:group_id].present?
      @group = Group.find_by_id(params[:group_id])
      return record_not_found if !@group.present?
      @condition_string += " #{@group.name} "
      group_scope = Question.from_group(@group.id)
    else
      group_scope = Question.where({})
    end
    
    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      return record_not_found if !@location.present?
      @condition_string += " #{@location.name} "
      location_scope = group_scope.by_location(@location)
      
      # take care of state only metrics if that's requested
      case filter.strip
      when 'in_state_experts'
        @question_list = location_scope.not_rejected.resolved_questions_by_in_state_responders(@location, @year_month).page((params[:page].present?) ? params[:page] : 1).per(30)
        @page_title = "Answered Questions for #{@condition_array} for #{@year_month} by In State Experts"
        @display_title = "Answered Questions for #{@condition_array} by In State Experts"
        @subtext_display = "for #{@year_month}"
        return
      when 'out_of_state_experts'
        @question_list = location_scope.not_rejected.resolved_questions_by_outside_state_responders(@location, @year_month).page((params[:page].present?) ? params[:page] : 1).per(30)
        @page_title = "Answered Questions for #{@condition_array} for #{@year_month} by Out of State Experts"
        @display_title = "Answered Questions for #{@condition_array} by Out of State Experts"
        @subtext_display = "for #{@year_month}"
        return
      end
      
      # county questions    
      if params[:county_id].present?
        @county = County.find_by_id(params[:county_id])
        return record_not_found if !@county.present?
        @condition_string += " #{@county.name}, #{@location.name} "
        location_scope = group_scope.by_county(@county)
      end
    else
      location_scope = group_scope
    end
    
    case filter.strip
    when 'answered'
      @question_list = location_scope.not_rejected.answered_list_for_year_month(@year_month).order('created_at DESC').page((params[:page].present?) ? params[:page] : 1).per(30)
    when 'asked'
      @question_list = location_scope.not_rejected.asked_list_for_year_month(@year_month).order('created_at DESC').page((params[:page].present?) ? params[:page] : 1).per(30)
    else
      @question_list = location_scope.submitted.not_rejected.order('created_at DESC').page((params[:page].present?) ? params[:page] : 1).per(30)
    end
    
    @page_title = "#{filter.capitalize} Questions for #{@condition_string} for #{@year_month}"
    @display_title = "#{filter.capitalize} Questions for #{@condition_string} "
    @subtext_display = "for #{@year_month}"
  end
  
  def expert_list
    @expert = User.find(params[:id])
    
    if(params[:filter] and ['assigned','answered'].include?(params[:filter]))
      filter = params[:filter]
    else
      filter = 'assigned'
    end

    if(params[:year_month])
      @year_month = params[:year_month]
    else
      @year_month = User.year_month_string(Date.today.year,Date.today.month)
    end

    case filter
    when 'assigned'
      @question_list = @expert.assigned_list_for_year_month(@year_month).order('created_at DESC').page((params[:page].present?) ? params[:page] : 1).per(30)
    when 'answered'
      @question_list = @expert.answered_list_for_year_month(@year_month).order('created_at DESC').page((params[:page].present?) ? params[:page] : 1).per(30)
    end

    @page_title = "#{filter.capitalize} Questions for #{@expert.name} (ID##{@expert.id}) for #{@year_month}"
    @display_title = "#{filter.capitalize} Questions for #{@expert.name}"
    @subtext_display = "for #{@year_month}"
    @breadcrumb_display = "#{filter.capitalize} Questions for #{@expert.name} for #{@year_month}"
  end
end