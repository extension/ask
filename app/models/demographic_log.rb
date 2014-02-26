# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class DemographicLog < ActiveRecord::Base
  ## includes
  ## attributes
  attr_accessible :demographic, :demographic_id, :changed_answers
  serialize :changed_answers

  ## constants
  ## associations
  belongs_to :demographic

  ## scopes
  ## validations
  ## filters
  ## class methods
  ## instance methods
end
