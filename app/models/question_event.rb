class QuestionEvent < ActiveRecord::Base
  belongs_to :question
  belongs_to :response
  belongs_to :initiator, :class_name => "User", :foreign_key => "initiated_by_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  belongs_to :previous_recipient, :class_name => "User", :foreign_key => "previous_recipient_id"
  belongs_to :previous_initiator,  :class_name => "User", :foreign_key => "previous_initiator_id"
  belongs_to :previous_handling_recipient, :class_name => "User", :foreign_key => "previous_handling_recipient_id"
  belongs_to :previous_handling_initiator,  :class_name => "User", :foreign_key => "previous_handling_initiator_id"
  
  
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
    question.contributing_content ? contributing_content = question.contributing_content : contributing_content = nil

    return self.log_event({:question => question,
                           :initiated_by => question.resolved_by,
                           :event_state => RESOLVED,
                           :response => question.current_response,
                           :contributing_content => contributing_content})
  end
  
    
end
