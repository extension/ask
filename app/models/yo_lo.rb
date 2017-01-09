# === COPYRIGHT:
# Copyright (c) North Carolina State University
# === LICENSE:
# see LICENSE file

class YoLo

  attr_accessor :ipaddress,:session

  def initialize(ipaddress,session)
    @ipaddress = ipaddress
    @session = session
  end

  def detected_location
    if(!@detected_location)
      @detected_location = Location.find_by_geoip(@ipaddress)
    end
    @detected_location
  end

  def detected_county
    if(!@detected_county)
      @detected_county = County.find_by_geoip(@ipaddress)
    end
    @detected_county
  end

  def location
    if(!@location)
      if(session[:yolo_location_id])
        @location = Location.where(id: session[:yolo_location_id]).first
      else
        @location = self.detected_location
        session[:yolo_location_id] = @location.id if(!@location.nil?)
      end
    end
    @location
  end

  def county
    if(!@county)
      if(session[:yolo_county_id])
        @county = County.where(id: session[:yolo_county_id]).first
      else
        @county = self.detected_county
        session[:yolo_county_id] = @county.id if(!@county.nil?)
      end
    end
    @county
  end

  def set_location(location)
    @location = location
    if(@location.nil?)
      session[:yolo_location_id] = nil
    else
      session[:yolo_location_id] = @location.id
    end
    # clear county if mismatch
    if(@county and @location and @county.location_id != @location.id)
      @county = nil
      session[:yolo_county_id] = nil
    end
  end

  def set_county(county)
    @county = county
    if(@county.nil?)
      session[:yolo_county_id] = nil
    else
      session[:yolo_county_id] = @county.id
    end
    # set location to the county location
    if(@county)
      @location = @county.location
      session[:yolo_location_id] = @location.id if(!@location.nil?)
    end

  end

end
