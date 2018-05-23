# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class Demographic < ActiveRecord::Base
  ## includes
  include MarkupScrubber

  ## attributes
  attr_accessible :demographic_question, :demographic_question_id, :user, :user_id, :response, :value

  ## constants
  ## associations
  belongs_to :demographic_question
  belongs_to :user

  ## scopes
  ## validations
  ## filters

  ## class methods
  ## instance methods

  def response=(response_text)
    write_attribute(:response, self.html_to_text(response_text))
  end

end
