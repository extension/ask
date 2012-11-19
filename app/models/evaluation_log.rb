# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EvaluationLog < ActiveRecord::Base
  serialize :changed_answers
  belongs_to :evaluation_answer
  attr_accessible :evaluation_answer, :evaluation_answer_id, :changed_answers
end
