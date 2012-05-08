# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer  "current_resolver"           # from resolved_by
      t.integer  "contributing_content_id"    # keep for legacy values, may not continue this going forward
      t.string   "status",                    :default => "",    :null => false
      t.text     "body",                      :null => false # from asked_question
      t.boolean  "private",                   :default => false
      t.integer  "assignee_id"                # from user_id
      t.boolean  "duplicate",                 :default => false, :null => false
      t.string   "external_app_id"
      t.string   "submitter_email"
      t.datetime "resolved_at"
      t.integer  "external_id"
      t.datetime "question_updated_at"
      t.text     "current_response"
      t.string   "current_resolver_email"     # from resolver_email
      t.string   "question_fingerprint",                         :null => false
      t.string   "submitter_firstname",       :default => "",    :null => false
      t.string   "submitter_lastname",        :default => "",    :null => false
      t.integer  "county_id"
      t.integer  "location_id"
      t.boolean  "spam",                      :default => false, :null => false
      t.string   "user_ip",                   :default => "",    :null => false
      t.string   "user_agent",                :default => "",    :null => false
      t.string   "referrer",                  :default => "",    :null => false
      t.string   "widget_name"
      t.integer  "status_state",                                 :null => false
      t.string   "zip_code"
      t.integer  "widget_id"
      t.integer  "submitter_id",              :default => 0
      t.boolean  "show_publicly",             :default => true
      t.datetime "last_assigned_at"
      t.datetime "last_opened_at",                               :null => false
      t.boolean  "is_api"
      t.string   "contributing_content_type"
      t.timestamps
    end

    #add_index "questions", ["body", "current_response"], :name => "question_response_full_index"
    add_index "questions", ["county_id"], :name => "fk_question_county"
    add_index "questions", ["created_at"], :name => "created_at_idx"
    add_index "questions", ["location_id"], :name => "fk_question_location"
    add_index "questions", ["question_fingerprint"], :name => "question_fingerprint_idx"
    add_index "questions", ["resolved_at"], :name => "resolved_at_idx"
    add_index "questions", ["current_resolver"], :name => "fk_current_resolver"
    add_index "questions", ["status_state"], :name => "status_state_idx"
    add_index "questions", ["submitter_id"], :name => "submitter_id_idx"
    add_index "questions", ["assignee_id"], :name => "fk_assignee"
    add_index "questions", ["widget_name"], :name => "widget_name_idx"
    add_index "questions", ["widget_id"], :name => "fk_widget_id"
  end
end
