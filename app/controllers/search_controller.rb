# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class SearchController < ApplicationController
  layout 'public'


  def all
    # take quotes out to see if it's a blank field and also strip out +, -, and "  as submitted by themselves
    if !params[:q] || params[:q].gsub(/["'+-]/, '').strip.blank?
      flash[:error] = "Empty/invalid search terms"
      return redirect_to root_url
    end



    @list_title = "Search for '#{params[:q]}'"
    if(Settings.elasticsearch_enabled)
      # elasticsearch pagination has a 10,000 limit - let's just stay under that  - pagination is 25 per by default
      if(params[:page].to_i < 400)
        @questions = QuestionsIndex.not_rejected.public_questions.fulltextsearch(params[:q]).page(params[:page])
      else
        @over_search_limit = true
        @questions = []
      end
    else
      @questions = Question.not_rejected.public_visible.pattern_search(params[:q]).page(params[:page])
    end
  end
end
