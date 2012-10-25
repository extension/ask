# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class YoLo < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  belongs_to :county
  belongs_to :detected_location, :class_name => "Location"
  belongs_to :detected_county,   :class_name => "County"


  def self.create_from_ip(ipaddress,current_user = nil)
    yolo = YoLo.create
    yolo.update_with_ip(ipaddress,current_user)
    yolo
  end

  def update_with_ip(ipaddress,current_user = nil)
    current_detected_location_id = self.detected_location_id
    current_detected_county_id = self.detected_county_id

    d_location = Location.find_by_geoip(ipaddress)
    d_county = County.find_by_geoip(ipaddress)

    self.user = current_user
    self.ipaddress = ipaddress
    if(d_location)
      self.detected_location = d_location
      self.detected_county = d_county

      if(self.location_id == 0)
        self.location = d_location
        self.county = d_county
      elsif(current_detected_location_id != d_location.id)
        self.location = d_location
        self.county = d_county
      elsif(d_county and current_detected_county_id != d_county.id)
        self.location = d_location
        self.county = d_county
      end
    end
    self.save
  end

  def county
    checkcounty = County.find_by_id(read_attribute(:county_id))
    if(checkcounty and checkcounty.location_id = self.location_id)
      checkcounty
    else
      nil
    end
  end

end