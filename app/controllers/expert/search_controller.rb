# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::SearchController < ApplicationController
  layout 'expert'
  before_filter :authenticate_user!
  before_filter :require_exid

  def all
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters 
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to expert_home_url
    end
  
    @list_title = "Search for '#{params[:q]}'"
    
    questions = Question.search do
                  fulltext(params[:q])
                  without(:status_state, Question::STATUS_REJECTED)
                  paginate :page => 1, :per_page => 10
                end
    @questions = questions.results
    
    experts = User.search do
              fulltext(params[:q]) do
                fields(:name)
              end
              with :is_blocked, false
              with :retired, false
              with :kind, 'User'
              paginate :page => 1, :per_page => 10
            end
    @experts = experts.results
    
    groups = Group.search do
               fulltext(params[:q])
               paginate :page => 1, :per_page => 10
             end
    @groups = groups.results
    render :action => 'index'
  end
  
  def questions
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters 
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to expert_home_url
    end
  
    @list_title = "Search on questions for '#{params[:q]}'"
    params[:page].present? ? (@page_title = "#{@list_title} - Page #{params[:page]}") : (@page_title = @list_title)
    questions = Question.search do
                  fulltext(params[:q])
                  without(:status_state, Question::STATUS_REJECTED)
                  paginate :page => params[:page], :per_page => 15
                end
    @questions = questions.results
    @page_title = "Search on questions for '#{params[:q]}'"
  end
  
  def experts
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters 
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to expert_home_url
    end
  
    @list_title = "Search on experts for '#{params[:q]}'"
    params[:page].present? ? (@page_title = "#{@list_title} - Page #{params[:page]}") : (@page_title = @list_title)
    experts = User.search do
              with :is_blocked, false
              with :retired, false
              with :kind, 'User'
              fulltext(params[:q]) do
                fields(:name)
              end
              paginate :page => params[:page], :per_page => 15
            end
    @experts = experts.results
    @page_title = "Search on questions for '#{params[:q]}'"
  end
  
  def groups
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters 
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to expert_home_url
    end
  
    @list_title = "Search on groups for '#{params[:q]}'"
    params[:page].present? ? (@page_title = "#{@list_title} - Page #{params[:page]}") : (@page_title = @list_title)
    groups = Group.search do
               fulltext(params[:q])
               paginate :page => params[:page], :per_page => 15
             end
    @groups = groups.results
    @page_title = "Search on questions for '#{params[:q]}'"
  end

end