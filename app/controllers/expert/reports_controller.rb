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
end