# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class ReportsController < ApplicationController
  before_filter :override_rows

  def index
    @question_stats = Question.answered.stats_by_yearweek('questions')
    @expert_stats = Question.answered.stats_by_yearweek('experts')
    @responsetime_stats = Question.answered.stats_by_yearweek('responsetime')
  end



  private

  def override_rows
    # setting a layout varialble so that we
    # can have control over the rows in the container
    @override_rows = true
  end


end