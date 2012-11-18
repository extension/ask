# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Demographic < ActiveRecord::Base
  belongs_to :demographic_question
  belongs_to :user
  has_many :demographic_logs
  attr_accessible :demographic_question, :demographic_question_id, :user, :user_id, :response, :value

  after_save :log_changed_answers


  def log_changed_answers
    if(self.changed? and !self.changes[:response].blank? and !self.changes[:response][0].blank?)
      self.demographic_logs.create(changed_answers: {original: self.changes[:response][0], new: self.changes[:response][1]})
    end
  end

end
