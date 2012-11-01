class QuestionEvent < ActiveRecord::Base
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
  
  after_create :create_question_event_notification
  
  
  ASSIGNED_TO = 1
  RESOLVED = 2
  MARKED_SPAM = 3
  MARKED_NON_SPAM = 4
  REACTIVATE = 5
  REJECTED = 6
  NO_ANSWER = 7
  RECATEGORIZED = 8
  WORKING_ON = 9
  EDIT_QUESTION = 10
  PUBLIC_RESPONSE = 11
  REOPEN = 12
  CLOSED = 13
  COMMENT = 14
  ASSIGNED_TO_GROUP = 15
  
  EVENT_TO_TEXT_MAPPING = { 1 => 'assigned to', 2 => 'resolved by', 3 => 'marked as spam', 4 => 'marked as non-spam', 5 => 're-activated by', 6 => 'rejected by', 7 => 'no answer given', 
                            8 => 're-categorized by', 9 => 'worked on by', 10 => 'edited question', 11 => 'public response', 12 => 'reopened', 13 => 'closed', 14 => 'commented', 15 => 'assigned to group' }
  
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
  
  def self.log_group_assignment(question, group, initiated_by, assignment_comment)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :recipient_group_id => group.id,
      :recipient_id => nil,
      :event_state => ASSIGNED_TO_GROUP,
      :response => assignment_comment})
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
  
  def self.log_spam(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => MARKED_SPAM})
  end
  
  def self.log_ham(question, initiated_by)
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by.id,
      :event_state => MARKED_NON_SPAM})
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
      #assigned and reassigned, submission ack
      if self.previous_event_id.nil? and !self.recipient_id.nil? #new incoming question
        Notification.create(notifiable: self, created_by: self.question.submitter, recipient_id: self.question.submitter.id, notification_type: Notification::AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT, delivery_time: 1.minute.from_now )
      end
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
    
end
