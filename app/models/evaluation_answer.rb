# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EvaluationAnswer < ActiveRecord::Base
  belongs_to :evaluation_question
  belongs_to :user
  belongs_to :question
  has_many :evaluation_logs
  attr_accessible :question, :question_id, :user, :user_id, :response, :value, :evaluation_question_id, :evaluation_question

  after_save :log_changed_answers

  def log_changed_answers
    if(self.changed? and !self.changes[:response].blank? and !self.changes[:response][0].blank?)
      self.evaluation_logs.create(changed_answers: {original: self.changes[:response][0], new: self.changes[:response][1]})
    end
  end
end
