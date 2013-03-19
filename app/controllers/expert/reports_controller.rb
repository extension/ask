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
    
    @my_groups = Array.new
      current_user.group_memberships.each do |membership|
      @my_groups << membership
    end
       
    if params[:county_id].present?
      @county = County.find_by_id(params[:county_id])
      @condition_array += " #{@county.name} "
    end
    
    if params[:location_id].present?
      @location = Location.find_by_id(params[:location_id])
      @condition_array += " #{@location.name} "
      @experts = User.exid_holder.not_retired.with_expertise_location(@location.id).order("users.last_active_at DESC").limit(20)
      # @experts = User.exid_holder.not_retired.questions_answered.limit(20)
    end
    
    if params[:group_id].present?
      @group = Group.find_by_id(params[:group_id])
      @my_groups << @group
      @my_groups = @my_groups.uniq
      @condition_array += " #{@group.name} "
    end
    
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
    
    @unanswered_questions_count = questions_based_on_report_filter('unanswered').count
    @questions_asked = questions_based_on_report_filter('asked', @year_month)
    @questions_answered = questions_based_on_report_filter('answered', @year_month)
  end
  
  def question_list
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