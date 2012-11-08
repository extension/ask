# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EvaluationAnswer < ActiveRecord::Base
  belongs_to :evaluation_question
  belongs_to :user
  belongs_to :question

  attr_accessible :question, :question_id, :user, :user_id, :response, :secondary_response, :value, :evaluation_question_id, :evaluation_question

end
