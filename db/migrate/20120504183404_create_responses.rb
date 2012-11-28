class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.integer  "resolver_id"
      t.integer  "submitter_id"
      t.integer  "question_id",                                  :null => false
      t.text     "body",                                         :null => false
      t.boolean  "sent",                      :default => false, :null => false
      t.integer  "contributing_question_id"
      t.text     "signature"
      t.string   "user_ip"
      t.string   "user_agent"
      t.string   "referrer"
      t.timestamps
    end
    
    add_index "responses", ["contributing_question_id"], :name => "idx_contributing_question"
    add_index "responses", ["resolver_id"], :name => "idx_resolver_id"
    add_index "responses", ["question_id"], :name => "idx_question_id"
    add_index "responses", ["submitter_id"], :name => "idx_submitter_id"  
  end
end
