# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class LocationEvent < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :location
  serialize :additionaldata

  # EVENT CODES
  LOCATION_EDIT_OFFICE_LINK = 201
  LOCATION_ADD_PRIMARY_GROUP = 220
  LOCATION_REMOVE_PRIMARY_GROUP = 221


  EVENT_STRINGS = {
    LOCATION_EDIT_OFFICE_LINK     => 'edited the office link',
    LOCATION_ADD_PRIMARY_GROUP    => 'added a primary group',
    LOCATION_REMOVE_PRIMARY_GROUP => 'removed a primary group'
  }

  def description
    EVENT_STRINGS[self.event_code]
  end

  def self.log_event(location, creator, recipient, event_code, additionaldata = nil)
    log_attributes = {}
    log_attributes[:location_id] = location.id
    log_attributes[:created_by] = creator.id
    log_attributes[:event_code] = event_code
    log_attributes[:additionaldata] = edit_hash

    return LocationEvent.create(log_attributes)
  end

end
