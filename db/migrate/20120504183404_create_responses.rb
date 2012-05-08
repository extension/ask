class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.integer  "resolver_id"
      t.integer  "submitter_id"
      t.integer  "question_id",                                  :null => false
      t.text     "body",                                         :null => false
      t.integer  "duration_since_last",                          :null => false
      t.boolean  "sent",                      :default => false, :null => false
      t.integer  "contributing_content_id"
      t.text     "signature"
      t.string   "user_ip"
      t.string   "user_agent"
      t.string   "referrer"
      t.string   "contributing_content_type"
      t.timestamps
    end
    
    add_index "responses", ["contributing_content_id", "contributing_content_type"], :name => "idx_contributing_content"
    add_index "responses", ["resolver_id"], :name => "idx_resolver_id"
    add_index "responses", ["question_id"], :name => "idx_question_id"
    add_index "responses", ["submitter_id"], :name => "idx_submitter_id"  
  end
end
