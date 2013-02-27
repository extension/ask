class UserEvent < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :user
  after_create :create_user_event_notification
  
  serialize :updated_user_attributes
  
  # USER EVENTS
  CHANGED_TAGS = 100
  CHANGED_VACATION_STATUS = 101
  
  USER_EVENT_STRINGS = {
    100 => 'changed tags',
    101 => 'changed vacation status'
  }
  
  
  def self.log_updated_tags(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, CHANGED_TAGS, edit_hash)
  end
  
  def self.log_updated_vacation_status(user, initiator, edit_hash)
    return self.log_user_changes(user, initiator, CHANGED_VACATION_STATUS, edit_hash)
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
      when CHANGED_TAGS
        Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.user_id, notification_type: Notification::AAE_EXPERT_TAG_EDIT, delivery_time: 1.minute.from_now )
      when CHANGED_VACATION_STATUS
        Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.user_id, notification_type: Notification::AAE_EXPERT_VACATION_EDIT, delivery_time: 1.minute.from_now )
      end
    end
  end
  
end
