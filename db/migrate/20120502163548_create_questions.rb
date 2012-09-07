# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer  "current_resolver_id"        # from resolved_by
      t.integer  "contributing_question_id"   # keep for legacy values, may not continue this going forward
      t.string   "status",                    :default => "",    :null => false
      t.text     "body",                      :null => false # from asked_question
      t.string   "title"
      t.boolean  "is_private",                :default => false
      t.integer  "is_private_reason"
      t.integer  "assignee_id"                # from user_id
      t.integer  "assigned_group_id",         :null => true
      t.boolean  "duplicate",                 :default => false, :null => false
      t.string   "external_app_id"
      t.string   "submitter_email"
      t.datetime "resolved_at"
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
      t.string   "group_name"
      t.integer  "status_state",                                 :null => false
      t.string   "zip_code"
      t.integer  "original_group_id"
      t.integer  "submitter_id",              :default => 0
      t.datetime "last_assigned_at"
      t.datetime "last_opened_at",                               :null => false
      t.boolean  "is_api"
      t.timestamps
    end

    add_index "questions", ["county_id"], :name => "fk_question_county"
    add_index "questions", ["created_at"], :name => "created_at_idx"
    add_index "questions", ["location_id"], :name => "fk_question_location"
    add_index "questions", ["question_fingerprint"], :name => "question_fingerprint_idx"
    add_index "questions", ["resolved_at"], :name => "resolved_at_idx"
    add_index "questions", ["current_resolver_id"], :name => "fk_current_resolver"
    add_index "questions", ["status_state"], :name => "status_state_idx"
    add_index "questions", ["submitter_id"], :name => "submitter_id_idx"
    add_index "questions", ["assignee_id"], :name => "fk_assignee"
    add_index "questions", ["assigned_group_id"], :name => "fk_group_assignee"
    add_index "questions", ["group_name"], :name => "group_name_idx"
    add_index "questions", ["original_group_id"], :name => "fk_original_group_id"
    add_index "questions", ["is_private"], :name => "fk_is_private"
    add_index "questions", ["contributing_question_id"], :name => "fk_contributing_question"
  end
end
