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
  
  
  
  
  
  
end
