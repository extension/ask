# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Expert::SearchController < ApplicationController
  layout 'public'
  
  
  def all
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves are apparently special characters 
    # for solr and will make it crash, and if you ain't got no q param, no search goodies for you!
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to home_url
    end
    
    @list_title = "Search for '#{params[:q]}'"
    
    questions = Question.search do
                  fulltext(params[:q])
                  without(:status_state, Question::STATUS_REJECTED)
                  with :is_private, false
                  paginate :page => 1, :per_page => 10
                end
    @questions = questions.results
  end
end