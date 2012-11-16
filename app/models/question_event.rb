# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class QuestionEvent < ActiveRecord::Base
  include MarkupScrubber

  belongs_to :question
  belongs_to :initiator, :class_name => "User", :foreign_key => "initiated_by_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :assigned_group, :class_name => "Group", :foreign_key => "recipient_group_id"
  belongs_to :previous_recipient, :class_name => "User", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "User", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "User", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "User", :foreign_key => "previous_handling_initiator_id"
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  belongs_to :previous_group, class_name: 'Group'
  belongs_to :changed_group, class_name: 'Group'

  after_create :create_question_event_notification

  # #'s 3 and 4 were the old marked spam and marked non spam question events from darmok, these were 
  # just pulled instead of renumbering all these so to not disturb the other status numbers being pulled over from the other sytem
  ASSIGNED_TO = 1
  RESOLVED = 2
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  TAG_CHANGE = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  CHANGED_GROUP = 16

  EVENT_TO_TEXT_MAPPING = { ASSIGNED_TO => 'assigned to',
                            RESOLVED => 'resolved by',
                            REACTIVATE => 're-activated by',
                            REJECTED => 'rejected by',
                            NO_ANSWER => 'no answer given',
                            TAG_CHANGE => 'tags edited by',
                            WORKING_ON => 'worked on by',
                            EDIT_QUESTION => 'edited question',
                            PUBLIC_RESPONSE => 'public response',
                            REOPEN => 'reopened',
                            CLOSED => 'closed',
                            COMMENT => 'commented',
                            ASSIGNED_TO_GROUP => 'assigned to group',
                            CHANGED_GROUP => 'group changed' }

  scope :latest, {:order => "created_at desc", :limit => 1}
  scope :latest_handling, {:conditions => "event_state IN (#{ASSIGNED_TO},#{ASSIGNED_TO_GROUP},#{RESOLVED},#{REJECTED},#{NO_ANSWER})",:order => "created_at desc", :limit => 1}
  scope :handling_events, :conditions => "event_state IN (#{ASSIGNED_TO},#{ASSIGNED_TO_GROUP},#{RESOLVED},#{REJECTED},#{NO_ANSWER})"


  def self.log_resolution(question)
    question.contributing_question ? contributing_question = question.contributing_question : contributing_question = nil

    return self.log_event({:question => question,
                           :initiator => question.current_resolver,
                           :event_state => RESOLVED,
                           :response => question.current_response,
                           :contributing_question => contributing_question})
  end
  
  def self.log_assignment(question, recipient, initiated_by, assignment_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_id => recipient.id,
      :event_state => ASSIGNED_TO,
      :response => assignment_comment})
  end
  
  def self.log_history_comment(question, initiated_by, history_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => COMMENT,
      :response => history_comment})
  end
  
  def self.log_group_assignment(question, group, initiated_by, assignment_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_group_id => group.id,
      :recipient_id => nil,
      :event_state => ASSIGNED_TO_GROUP,
      :response => assignment_comment})
  end

  def self.log_group_change(options = {})
    question = options[:question]
    previous_group = options[:old_group]
    changed_group = options[:new_group]
    initiated_by = options[:initiated_by]
    if(question and previous_group and changed_group and initiated_by)
      return self.log_event(question: question, previous_group_id: previous_group.id, changed_group_id: changed_group.id, initiated_by_id: initiated_by.id, event_state: CHANGED_GROUP)
    else
      return false
    end
  end
  
  def self.log_tag_change(question, initiated_by, tags, previous_tags)
    return self.log_event({:question => question, 
                           :initiated_by_id => initiated_by.id,
                           :tags => tags,
                           :previous_tags => previous_tags,
                           :event_state => TAG_CHANGE
                           })
  end
  
  def self.log_reopen(question, recipient, initiated_by, assignment_comment)
    question.update_attribute(:last_opened_at, Time.now)
    
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_id => recipient.id,
      :event_state => REOPEN,
      :response => assignment_comment})
  end
  
  def self.log_public_edit(question)
    return self.log_event({:question => question, 
      :event_state => EDIT_QUESTION, 
      :additional_data => question.body})    
  end
  
  def self.log_public_response(question, submitter_id)
    return self.log_event({:question => question,
      :initiated_by_id => User.system_user_id,
      :event_state => PUBLIC_RESPONSE,
      :submitter_id => submitter_id})  
  end
  
  def self.log_reopen_to_group(question, group, initiated_by, assignment_comment)
    question.update_attribute(:last_opened_at, Time.now)
    
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_group_id => group.id,
      :event_state => REOPEN,
      :response => assignment_comment})
  end
  
  def self.log_rejection(question)
    return self.log_event({:question => question,
      :initiated_by_id => question.current_resolver_id,
      :event_state => REJECTED,
      :response => question.current_response})
  end
  
  def self.log_reactivate(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => REACTIVATE})
  end
  
  def self.log_no_answer(question)
    return self.log_event({:question => question,
      :initiator => question.current_resolver,
      :event_state => NO_ANSWER,
      :response => question.current_response})
  end
  
  def self.log_close(question, initiated_by, close_out_reason)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => CLOSED,
      :response => close_out_reason})
  end
  
  def self.log_event(create_attributes = {})
    time_of_this_event = Time.now.utc
    question = create_attributes[:question]
    if create_attributes[:event_state] == ASSIGNED_TO || create_attributes[:event_state] == ASSIGNED_TO_GROUP
      question.update_attribute(:last_assigned_at, time_of_this_event)
    end

    # gathering of previous events for metrics gathering for things like duration and handling rate, 
    # if we want to keep track of this for a group context (user is being tracked here), we'll need to add more columns to the schema for groups
    
    # get last event
    last_event = question.question_events.latest[0]
    if last_event.present?
      create_attributes[:duration_since_last] = (time_of_this_event - last_event.created_at).to_i
      create_attributes[:previous_recipient_id] = last_event.recipient_id
      create_attributes[:previous_initiator_id] = last_event.initiated_by_id
      create_attributes[:previous_event_id] = last_event.id
      # if not a handling event, get the last handling event
      if(!last_event.is_handling_event?)
        if(last_handling_events = question.question_events.latest_handling && !last_handling_events.blank?)
          last_handling_event = last_handling_events[0]
          create_attributes[:previous_handling_event_id] = last_handling_event.id          
          create_attributes[:duration_since_last_handling_event] = (time_of_this_event - last_handling_event.created_at).to_i
          create_attributes[:previous_handling_event_state] = last_handling_event.event_state
          create_attributes[:previous_handling_recipient_id] = last_handling_event.recipient_id
          create_attributes[:previous_handling_initiator_id] = last_handling_event.initiated_by_id
        end
      else
        # last_event was a handling event - so use the last_event details to fill those values in
        create_attributes[:previous_handling_event_id] = last_event.id
        create_attributes[:duration_since_last_handling_event] = (time_of_this_event - last_event.created_at).to_i
        create_attributes[:previous_handling_event_state] = last_event.event_state
        create_attributes[:previous_handling_recipient_id] = last_event.recipient_id
        create_attributes[:previous_handling_initiator_id] = last_event.initiated_by_id
      end
    end

    return QuestionEvent.create(create_attributes)    
  end
  
  def is_handling_event?
    return ((self.event_state == ASSIGNED_TO) || (self.event_state == ASSIGNED_TO_GROUP) || (self.event_state == RESOLVED) || (self.event_state==REJECTED) || (self.event_state==NO_ANSWER))
  end
  
  # NOTE THAT THE RECIPIENT_ID (AND PREVIOUS_RECIPIENT_ID AND PREVIOUS_HANDLING_RECIPIENT_ID) CAN BE NULL HERE DUE TO ASSIGNMENT TO GROUPS IN WHICH THE RECIPIENT_GROUP_ID IS SET
  def create_question_event_notification
    case self.event_state
    when ASSIGNED_TO
      #assigned and reassigned
      if (self.recipient_id != self.previous_handling_recipient_id) && (self.recipient_id != self.previous_handling_initiator_id) #reassigned
        # Notification.create(notifiable: self, created_by: self.initiated_by_id, recipient_id: self.previous_handling_recipient_id, notification_type: Notification::AAE_REASSIGNMENT, delivery_time: 1.minute.from_now ) unless self.previous_handling_recipient_id.nil?
      end
        Notification.create(notifiable: self, created_by: self.initiated_by_id, recipient_id: self.recipient_id, notification_type: Notification::AAE_ASSIGNMENT, delivery_time: 1.minute.from_now ) unless self.recipient_id.nil?
    when REJECTED
      Notification.create(notifiable: self, created_by: self.initiated_by_id, recipient_id: self.previous_recipient_id, notification_type: Notification::AAE_REJECT, delivery_time: 1.minute.from_now ) unless self.previous_recipient_id.nil?
    when EDIT_QUESTION
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.question.assignee.id, notification_type: Notification::AAE_PUBLIC_EDIT, delivery_time: 1.minute.from_now ) unless self.question.assignee.nil?
    when PUBLIC_RESPONSE
      Notification.create(notifiable: self, created_by: 1, recipient_id: self.question.current_resolver.id, notification_type: Notification::AAE_PUBLIC_COMMENT, delivery_time: 1.minute.from_now )
    when RESOLVED
      Notification.create(notifiable: self, created_by: self.initiated_by_id, recipient_id: self.question.submitter.id, notification_type: Notification::AAE_PUBLIC_EXPERT_RESPONSE, delivery_time: 1.minute.from_now )
    else
      true
    end
  end

  # attr_writer override for response to scrub html
  def response=(response)
    write_attribute(:response, self.cleanup_html(response))
  end

    
end
