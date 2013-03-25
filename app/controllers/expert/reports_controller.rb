# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::ReportsController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid
  
  # TODO: put a check in here to make sure the group, county, location id's actually exist -- ATH
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
      @my_groups << @group
      @my_groups = @my_groups.uniq
      @experts = User.group_membership_for(@group.id).by_question_event_count(QuestionEvent::RESOLVED,{limit: 40, yearmonth: @year_month})
    end
    
    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      @condition_array += " #{@location.name} "
      if defined?(@group) && @group.present?
        @experts = @location.users_with_origin.group_membership_for(@group.id).by_question_event_count(QuestionEvent::RESOLVED,{limit: 40, yearmonth: @year_month})
      else
        @experts = @location.users_with_origin.by_question_event_count(QuestionEvent::RESOLVED,{limit: 40, yearmonth: @year_month})
      end
      
      # get number of questions resolved by experts in state
      @resolved_by_state_experts = Question.not_rejected.by_location(@location).resolved_questions_by_in_state_responders(@location, @year_month, defined?(@group) ? @group : nil).count
      
      # get number of responses by experts in state
      responses_by_state_experts = Question.not_rejected.by_location(@location).responses_by_in_state_responders(@location, @year_month, defined?(@group) ? @group : nil)
      
      # get number of questions resolved by experts out of state
      @resolved_by_outside_state_experts = Question.not_rejected.by_location(@location).resolved_questions_by_outside_state_responders(@location, @year_month, defined?(@group) ? @group : nil).count
    
      # get number of responses by experts out of state for questions from this state
      responses_by_outside_state_experts = Question.not_rejected.by_location(@location).responses_by_outside_state_responders(@location, @year_month, defined?(@group) ? @group : nil)
      
      # get number of responses for state questions
      responses = Question.not_rejected.by_location(@location).resolved_response_list_for_year_month(@year_month, defined?(@group) ? @group : nil)
    end
       
    if params[:county_id].present?
      @county = County.find_by_id(params[:county_id])
      @condition_array = " #{@county.name}, #{@location.name} "
      if defined?(@group) && @group.present?
        @experts = @county.users_with_origin.group_membership_for(@group.id).by_question_event_count(QuestionEvent::RESOLVED, {limit: 40, yearmonth: @year_month})
      else
        @experts = @county.users_with_origin.by_question_event_count(QuestionEvent::RESOLVED, {limit: 40, yearmonth: @year_month})
      end
      
      # get number of responses for county
      responses = Question.not_rejected.by_county(@county).resolved_response_list_for_year_month(@year_month, defined?(@group) ? @group : nil)
    end  
    
    @response_count = responses.count
    @responder_count = responses.map{|r| r.initiated_by_id}.uniq.count
    
    @responses_by_in_state_count = responses_by_state_experts.count
    @responders_in_state_count = responses_by_state_experts.map{|r| r.initiated_by_id}.uniq.count
    
    @responses_by_outside_state_count = responses_by_outside_state_experts.count
    @responders_outside_state_count = responses_by_outside_state_experts.map{|r| r.initiated_by_id}.uniq.count
    
    @condition_array += " #{@group.name} " if defined?(@group) && @group.present?
    
    @unanswered_questions_count = questions_based_on_report_filter('unanswered').count
    @questions_asked = questions_based_on_report_filter('asked', @year_month)
    @questions_answered = questions_based_on_report_filter('answered', @year_month)
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
    @condition_array = ""
    if(params[:year_month])
      @year_month = params[:year_month]
    else
      @year_month = User.year_month_string(Date.today.year,Date.today.month)
    end
    
    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      @condition_array += " #{@location.name} "
    end
       
    if params[:county_id].present? && !["in_state_experts", "out_of_state_experts"].include?(params[:filter].strip)
      @county = County.find_by_id(params[:county_id])
      @condition_array = " #{@county.name}, #{@location.name} "
    end
    
    if params[:group_id].present?
      @group = Group.find_by_id(params[:group_id])
      @condition_array += " #{@group.name} "
    end
    
    if(params[:filter] && ['answered','asked'].include?(params[:filter]))
      filter = params[:filter]
    elsif params[:filter] && params[:filter].strip == 'in_state_experts' && defined?(@location) && @location.present? && defined?(@year_month) && @year_month.present?
      @question_list = Question.resolved_questions_by_in_state_responders(@location, @year_month, defined?(@group) ? @group : nil)
      @page_title = "Answered Questions for #{@condition_array} for #{@year_month} by In State Experts"
      @display_title = "Answered Questions for #{@condition_array} by In State Experts"
      @subtext_display = "for #{@year_month}"
      return
    elsif params[:filter] && params[:filter].strip == 'out_of_state_experts' && defined?(@location) && @location.present? && defined?(@year_month) && @year_month.present?
      @question_list = Question.resolved_questions_by_outside_state_responders(@location, @year_month, defined?(@group) ? @group : nil)
      @page_title = "Answered Questions for #{@condition_array} for #{@year_month} by Out of State Experts"
      @display_title = "Answered Questions for #{@condition_array} by Out of State Experts"
      @subtext_display = "for #{@year_month}"
      return
    else
      filter = 'answered'
    end
    
    @question_list = questions_based_on_report_filter(filter, @year_month)

    @page_title = "#{filter.capitalize} Questions for #{@condition_array} for #{@year_month}"
    @display_title = "#{filter.capitalize} Questions for #{@condition_array} "
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
      @question_list = @expert.assigned_list_for_year_month(@year_month).order('created_at DESC')
    when 'answered'
      @question_list = @expert.answered_list_for_year_month(@year_month).order('created_at DESC')
    end

    @page_title = "#{filter.capitalize} Questions for #{@expert.name} (ID##{@expert.id}) for #{@year_month}"
    @display_title = "#{filter.capitalize} Questions for #{@expert.name}"
    @subtext_display = "for #{@year_month}"
    @breadcrumb_display = "#{filter.capitalize} Questions for #{@expert.name} for #{@year_month}"
  end
end