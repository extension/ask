class QuestionEvent < ActiveRecord::Base
  belongs_to :question
  belongs_to :initiator, :class_name => "User", :foreign_key => "initiated_by_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :previous_recipient, :class_name => "User", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "User", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "User", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "User", :foreign_key => "previous_handling_initiator_id"
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  
  scope :latest, {:order => "created_at desc", :limit => 1}
  
  
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
  
  EVENT_TO_TEXT_MAPPING = { 1 => 'assigned to', 2 => 'resolved by', 3 => 'marked as spam', 4 => 'marked as non-spam', 5 => 're-activated by', 6 => 'rejected by', 7 => 'no answer given', 
                            8 => 're-categorized by', 9 => 'worked on by', 10 => 'edited question', 11 => 'public response', 12 => 'reopened', 13 => 'closed', 14 => 'commented' }
  
  
  
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
      :initiated_by_id => initiated_by,
      :recipient => recipient,
      :event_state => ASSIGNED_TO,
      :response => assignment_comment})
  end
  
  def self.log_reopen(question, recipient, initiated_by, assignment_comment)
    question.update_attribute(:last_opened_at, Time.now)
    
    return self.log_event({:question => question,
      :initiated_by_id => initiated_by,
      :recipient => recipient,
      :event_state => REOPEN,
      :response => assignment_comment})
  end
  
  def self.log_event(create_attributes = {})
    time_of_this_event = Time.now.utc
    question = create_attributes[:question]
    if create_attributes[:event_state] == ASSIGNED_TO
      question.update_attribute(:last_assigned_at, time_of_this_event)
    end

    # get last event
    last_event = question.question_events.latest[0]
    if last_event.present?
      create_attributes[:duration_since_last] = (time_of_this_event - last_event.created_at).to_i
      create_attributes[:previous_recipient_id] = last_event.recipient_id
      create_attributes[:previous_initiator_id] = last_event.initiated_by_id
      create_attributes[:previous_event_id] = last_event.id
      # if not a handling event, get the last handling event
      if(!last_event.is_handling_event?)
        if(last_handling_events = question.question_events.latest_handling && !last_handling_events.empty?)
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
    return ((self.event_state == ASSIGNED_TO) or (self.event_state == RESOLVED) or (self.event_state==REJECTED) or (self.event_state==NO_ANSWER))
  end
  
    
end
