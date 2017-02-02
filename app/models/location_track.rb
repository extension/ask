# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class LocationTrack < ActiveRecord::Base
  belongs_to :referer_track
  belongs_to :location
end
