class GroupEvent < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :group
  after_create :create_group_event_notification
  
  serialize :updated_group_values
  
  # GROUP EVENTS
  GROUP_ACTIVITY = 200
  GROUP_ACTIVITY_START = 201
  GROUP_ACTIVITY_END = 599
  
  GROUP_JOIN = 201
  GROUP_WANTS_TO_JOIN = 202
  GROUP_LEFT= 203
  GROUP_INVITATION= 204
  GROUP_ACCEPT_INVITATION= 205
  GROUP_DECLINE_INVITATION= 206
  GROUP_DONT_WANT_TO_JOIN = 207
  GROUP_INTEREST = 208
  GROUP_NO_INTEREST = 209
  
  GROUP_INVITED_AS_LEADER = 210
  GROUP_INVITED_AS_MEMBER = 211
  GROUP_ADDED_AS_LEADER = 212
  GROUP_ADDED_AS_MEMBER = 213
  GROUP_REMOVED_AS_LEADER = 214
  GROUP_REMOVED_AS_MEMBER = 215
  GROUP_INVITATION_RESCINDED = 216
  
  GROUP_INVITE_REMINDER = 308
  
  GROUP_UPDATE_INFORMATION = 401
  GROUP_CREATED_LIST = 402
  GROUP_TAGGED = 403

  CREATED_GROUP = 110
  LIST_POST = 501
  
  GROUP_EDITED_ATTRIBUTES = 600
  
  GROUP_EVENT_STRINGS = {
    205 => 'accepted group invitation',
    212 => 'added as group leader',
    213 => 'added as group member',
    402 => 'created group list',
    206 => 'declined group invitation',
    208 => 'indicated interest in group',
    204 => 'group invitation',
    216 => 'group invitation rescinded',
    210 => 'invited group leader',
    211 => 'invited group member',
    308 => 'group invite reminder',
    201 => 'joined group',
    203 => 'left group',
    209 => 'indicated no interest in group',
    207 => 'does not want to join group',
    214 => 'removed as group leader',
    215 => 'removed as group member',
    403 => 'tagged group',
    401 => 'updated group information',
    202 => 'wants to join group',
    110 => 'created group',
    501 => 'posted to list',
    600 => 'edited attributes'
  }
  
  def self.log_group_join(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_JOIN)
  end
  
  def self.log_group_leave(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_LEFT)
  end
  
  def self.log_added_as_leader(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_ADDED_AS_LEADER)
  end
  
  def self.log_removed_as_leader(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_REMOVED_AS_LEADER)
  end
  
  def self.log_edited_attributes(group, initiator, recipient, edit_hash)
    return self.log_group_changes(group, initiator, recipient, GROUP_EDITED_ATTRIBUTES, edit_hash)
  end
  
  def self.log_group_changes(group, initiator, recipient, event_code, edit_hash = nil)
    log_attributes = {}
    log_attributes[:created_by] = initiator.id
    log_attributes[:recipient_id] = recipient.present? ? recipient.id : nil
    log_attributes[:description] = GROUP_EVENT_STRINGS[event_code]
    log_attributes[:event_code] = event_code
    log_attributes[:group_id] = group.id
    log_attributes[:updated_group_values] = edit_hash
    
    return GroupEvent.create(log_attributes)
  end
  
  def create_group_event_notification
    case self.event_code
    when GROUP_JOIN
      Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.recipient_id, notification_type: Notification::GROUP_USER_JOIN, delivery_time: 1.minute.from_now )
    when GROUP_LEFT
      Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.recipient_id, notification_type: Notification::GROUP_USER_LEFT, delivery_time: 1.minute.from_now )
    when GROUP_ADDED_AS_LEADER
      Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.recipient_id, notification_type: Notification::GROUP_LEADER_JOIN, delivery_time: 1.minute.from_now )
    when GROUP_REMOVED_AS_LEADER
      Notification.create(notifiable: self, created_by: self.created_by, recipient_id: self.recipient_id, notification_type: Notification::GROUP_LEADER_LEFT, delivery_time: 1.minute.from_now )
    end
  end
  
end
