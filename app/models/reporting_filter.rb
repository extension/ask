# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class ReportingFilter

  attr_accessor :question_scope

  YEARWEEK_RESOLVED = 'YEARWEEK(questions.resolved_at,3)'

  def initialize(options = {})
    self.question_scope = Question.closed_not_rejected
  end

  def stats_by_year_week
    # YEARWEEK(node_activities.created_at,3)
    self.question_scope.group(YEARWEEK_RESOLVED).count
  end







end
