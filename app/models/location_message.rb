# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LocationMessage < ActiveRecord::Base
  belongs_to :editor, :class_name => "User", :foreign_key => "edited_by"
  belongs_to :location
end
