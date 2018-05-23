# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class EvaluationAnswer < ActiveRecord::Base
  ## includes
  include MarkupScrubber

  ## attributes
  attr_accessible :question, :question_id, :user, :user_id, :response, :value, :evaluation_question_id, :evaluation_question

  ## constants

  ## associations
  belongs_to :evaluation_question
  belongs_to :user
  belongs_to :question

  ## scopes

  ## validations

  ## filters
  after_save :update_question_data

  ## class methods

  ## instance methods

  def response=(response_text)
    write_attribute(:response, self.html_to_text(response_text))
  end

  def update_question_data
    self.question.update_data_cache
  end

end
