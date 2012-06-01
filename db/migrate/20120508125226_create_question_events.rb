class CreateQuestionEvents < ActiveRecord::Migration
  def change
    create_table :question_events do |t|
      t.integer  "question_id", :null => false
      t.integer  "submitter_id"
      t.integer  "initiated_by_id"
      t.integer  "recipient_id"
      t.integer  "response_id"
      t.text     "response"
      t.integer  "event_state", :null => false
      t.integer  "contributing_content_id"
      t.text     "tags"
      t.text     "additional_data"
      t.integer  "previous_event_id"
      t.integer  "duration_since_last"
      t.integer  "previous_recipient_id"
      t.integer  "previous_initiator_id"
      t.integer  "previous_handling_event_id"
      t.integer  "duration_since_last_handling_event"
      t.integer  "previous_handling_event_state"
      t.integer  "previous_handling_recipient_id"
      t.integer  "previous_handling_initiator_id"
      t.text     "previous_tags"
      t.string   "contributing_content_type"
      t.timestamps
    end
  
    add_index "question_events", ["created_at", "event_state", "previous_handling_recipient_id"], :name => "idx_handling"
    add_index "question_events", ["initiated_by_id"], :name => "idx_initiated_by"
    add_index "question_events", ["recipient_id"], :name => "idx_recipient_id"
    add_index "question_events", ["question_id"], :name => "idx_question_id"
    add_index "question_events", ["submitter_id"], :name => "idx_submitter_id"
  end
end
