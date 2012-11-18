# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class DemographicLog < ActiveRecord::Base
  serialize :changed_answers
  belongs_to :demographic
  attr_accessible :demographic, :demographic_id, :changed_answers
end
