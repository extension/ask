# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class ReportsController < ApplicationController
  before_filter :override_rows

  def index
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


  private

  def override_rows
    # setting a layout varialble so that we
    # can have control over the rows in the container
    @override_rows = true
  end


end