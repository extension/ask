# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class NotificationException < ActiveRecord::Base
  belongs_to :question
  belongs_to :user
end
