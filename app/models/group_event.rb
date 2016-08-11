class GroupEvent < ActiveRecord::Base
  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :group
  after_create :create_group_event_notification

  serialize :updated_group_values

  # GROUP EVENTS
  GROUP_JOIN = 201
  GROUP_LEFT= 203
  GROUP_REMOVE= 203
  GROUP_ADDED_AS_LEADER = 212
  GROUP_REMOVED_AS_LEADER = 214
  CREATED_GROUP = 110
  GROUP_EDITED_ATTRIBUTES = 600

  GROUP_EVENT_STRINGS = {
    212 => 'joined group leadership',
    201 => 'joined group',
    203 => 'left group',
    203 => 'removed from group',
    214 => 'left group leadership',
    110 => 'created group',
    600 => 'edited attributes'
  }

  def self.log_group_creation(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, CREATED_GROUP)
  end

  def self.log_group_join(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_JOIN)
  end

  def self.log_group_leave(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_LEFT)
  end

  def self.log_group_remove(group, initiator, recipient)
    return self.log_group_changes(group, initiator, recipient, GROUP_REMOVE)
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
