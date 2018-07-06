# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::SearchController < ApplicationController
  layout 'expert'
  before_filter :signin_required


  def all
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to expert_home_url
    end

    @list_title = "Search Results for '#{params[:q]}'"
    @number_passed = false

    # special "id of question, expert or group check"
    if (id_number = params[:q].cast_to_i) > 0
      @number_passed = true
      @questions = Question.where(id: id_number).page(1)
      @experts = User.where(id: id_number, kind: 'User').page(1)
      @groups = Group.where(id: id_number).page(1)
    else
      # check to see if what was entered looks like an email address.
      # if so, we'll also use it to look up questions submitted from said email address
      if (params[:q] =~ /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i)
        @user_email = true
        if user = User.find_by_email(params[:q].strip)
          @user_email_id = user.id
        else
          @user_email_id = nil
        end
      else
        @user_email = false
        @user_email_id = nil
      end

      limit_to_count = 10
      @questions = QuestionsIndex.not_rejected.fulltextsearch(params[:q]).limit(limit_to_count).load
      @experts = UsersIndex.available.fulltextsearch(params[:q]).limit(limit_to_count).order(last_activity_at: :desc).load
      @groups = GroupsIndex.fulltextsearch(params[:q]).limit(limit_to_count).load
    end

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

    @list_title = "Search for Experts with '#{params[:q]}' in the name or bio"
    params[:page].present? ? (@page_title = "#{@list_title} - Page #{params[:page]}") : (@page_title = @list_title)
    @experts = UsersIndex.available.fulltextsearch(params[:q]).limit(15).order(last_activity_at: :desc).page(params[:page])
    @page_title = "Search on questions for '#{params[:q]}'"
  end

  def groups
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to expert_home_url
    end

    @list_title = "Search for Groups with '#{params[:q]}' in the name or description"
    params[:page].present? ? (@page_title = "#{@list_title} - Page #{params[:page]}") : (@page_title = @list_title)
    groups = Group.search do
               fulltext(params[:q])
               paginate :page => params[:page], :per_page => 15
             end
    @groups = groups.results
    @page_title = "Search on questions for '#{params[:q]}'"
  end

end
