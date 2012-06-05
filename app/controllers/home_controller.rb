# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class HomeController < ApplicationController
  def index
    @recent_questions = Question.find(:all, :limit => 10, :order => 'created_at DESC')
  end
end
