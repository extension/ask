# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class HomeController < ApplicationController
  layout 'public'
  
  def index
    @recent_questions = Question.public_visible.find(:all, :limit => 10, :order => 'created_at DESC')
  end
  
  def private_page
  end
  
  def ask
    # the Question Wrangler group id is 38
    @group = Group.find_by_id("38")
  end
  
end
