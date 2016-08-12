class UserEvent < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :user
  after_create :create_user_event_notification

  serialize :updated_user_attributes

  # USER EVENTS
  CHANGED_TAGS = 100
  CHANGED_VACATION_STATUS = 101
  ADDED_LOCATION = 102
  REMOVED_LOCATION = 103
  ADDED_COUNTY = 104
  REMOVED_COUNTY = 105
  ADDED_TAGS = 106
  REMOVED_TAGS = 107
  UPDATED_DESCRIPTION = 108
  UPDATED_PROFILE = 109
  UPDATED_ANSWERING_PREFS = 110
  REMOVED_GROUP = 111

  USER_EVENT_STRINGS = {
    100 => 'changed tags',
    101 => 'changed vacation status',
    102 => 'added expertise location',
    103 => 'removed expertise location',
    104 => 'added expertise county',
    105 => 'removed expertise county',
    106 => 'added expertise tag',
    107 => 'removed expertise tag',
    108 => 'updated description',
    109 => 'updated profile',
    110 => 'updated answering preferences',
    111 => 'removed from group'
  }

  def self.log_generic_user_event(user, initiator, edit_hash, user_event)
    return self.log_user_changes(user, initiator, user_event, {what_changed: edit_hash})
  end

  def self.log_removed_group(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, REMOVED_GROUP, edit_hash)
  end

  def self.log_added_tags(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, ADDED_TAGS, edit_hash)
  end

  def self.log_removed_tags(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, REMOVED_TAGS, edit_hash)
  end

  def self.log_updated_vacation_status(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, CHANGED_VACATION_STATUS, edit_hash)
  end

  def self.log_added_location(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, ADDED_LOCATION, edit_hash)
  end

  def self.log_removed_location(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, REMOVED_LOCATION, edit_hash)
  end

  def self.log_added_county(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, ADDED_COUNTY, edit_hash)
  end

  def self.log_removed_county(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, REMOVED_COUNTY, edit_hash)
  end

  def self.log_user_changes(user, initiator, event_code, edit_hash = nil)
    log_attributes = {}
    log_attributes[:created_by] = initiator.id
    log_attributes[:user_id] = user.id
    log_attributes[:description] = USER_EVENT_STRINGS[event_code]
    log_attributes[:event_code] = event_code
    log_attributes[:updated_user_attributes] = edit_hash

    return UserEvent.create(log_attributes)
  end

  def create_user_event_notification
    if self.creator != self.user
      case self.event_code
      when ADDED_TAGS, REMOVED_TAGS
        if !Notification.pending_tag_edit_notification?(self)
          Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.user_id,
                              notification_type: Notification::AAE_EXPERT_TAG_EDIT, delivery_time: 1.minute.from_now )
        end
      when CHANGED_VACATION_STATUS
        Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.user_id,
                            notification_type: Notification::AAE_EXPERT_VACATION_EDIT, delivery_time: 1.minute.from_now )
      when REMOVED_GROUP
        Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.user_id,
                            notification_type: Notification::AAE_EXPERT_GROUP_EDIT, delivery_time: 1.minute.from_now )                            
      when ADDED_LOCATION, REMOVED_LOCATION, ADDED_COUNTY, REMOVED_COUNTY
        if !Notification.pending_location_edit_notification?(self)
          Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.user_id,
                              notification_type: Notification::AAE_EXPERT_LOCATION_EDIT, delivery_time: 1.minute.from_now )
        end
      end
    end
  end

end
