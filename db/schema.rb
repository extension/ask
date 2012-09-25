# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120918192757) do

  create_table "assets", :force => true do |t|
    t.string   "type"
    t.integer  "assetable_id"
    t.string   "assetable_type"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "authmaps", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "authname",   :null => false
    t.string   "source",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "authmaps", ["authname", "source"], :name => "index_authmaps_on_authname_and_source", :unique => true
  add_index "authmaps", ["user_id"], :name => "index_authmaps_on_user_id"

  create_table "comments", :force => true do |t|
    t.text     "content",                           :null => false
    t.string   "ancestry"
    t.integer  "user_id",                           :null => false
    t.integer  "question_id",                       :null => false
    t.boolean  "parent_removed", :default => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "comments", ["ancestry"], :name => "idx_comments_on_ancestry"
  add_index "comments", ["user_id", "question_id"], :name => "idx_comments_on_user_id_and_question_id"

  create_table "counties", :force => true do |t|
    t.integer  "fipsid",                    :null => false
    t.integer  "location_id",               :null => false
    t.integer  "state_fipsid",              :null => false
    t.string   "countycode",   :limit => 3, :null => false
    t.string   "name",                      :null => false
    t.string   "censusclass",  :limit => 2, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "counties", ["location_id"], :name => "idx_counties_on_location_id"
  add_index "counties", ["name"], :name => "idx_counties_on_name"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "group_connections", :force => true do |t|
    t.integer  "user_id",                              :null => false
    t.integer  "group_id",                             :null => false
    t.string   "connection_type",                      :null => false
    t.integer  "connection_code"
    t.boolean  "send_notifications", :default => true
    t.integer  "connected_by"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "group_connections", ["connection_type"], :name => "idx_group_connections_on_connection_type"
  add_index "group_connections", ["user_id", "group_id"], :name => "fk_user_group", :unique => true

  create_table "group_counties", :force => true do |t|
    t.integer "county_id", :default => 0, :null => false
    t.integer "group_id",  :default => 0, :null => false
  end

  add_index "group_counties", ["group_id", "county_id"], :name => "fk_counties_groups", :unique => true

  create_table "group_events", :force => true do |t|
    t.integer  "created_by",   :null => false
    t.integer  "recipient_id"
    t.string   "description"
    t.integer  "event_code"
    t.integer  "group_id",     :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "group_events", ["created_by"], :name => "idx_group_events_created_by"
  add_index "group_events", ["group_id"], :name => "idx_group_events_group_id"
  add_index "group_events", ["recipient_id"], :name => "idx_group_events_recipient_id"

  create_table "group_locations", :force => true do |t|
    t.integer "location_id", :default => 0, :null => false
    t.integer "group_id",    :default => 0, :null => false
  end

  add_index "group_locations", ["group_id", "location_id"], :name => "fk_locations_groups", :unique => true

  create_table "groups", :force => true do |t|
    t.string   "name",                                            :null => false
    t.text     "description"
    t.boolean  "widget_public_option",         :default => true
    t.boolean  "active",                       :default => true
    t.boolean  "assignment_outside_locations", :default => true
    t.boolean  "individual_assignment",        :default => true
    t.integer  "created_by",                                      :null => false
    t.string   "widget_fingerprint"
    t.boolean  "widget_upload_capable"
    t.boolean  "widget_show_location"
    t.boolean  "widget_show_title"
    t.boolean  "widget_enable_tags"
    t.integer  "widget_location_id"
    t.integer  "widget_county_id"
    t.string   "old_widget_url"
    t.boolean  "group_notify",                 :default => false
    t.integer  "darmok_expertise_id"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
  end

  add_index "groups", ["name"], :name => "idx_group_name", :unique => true
  add_index "groups", ["widget_fingerprint"], :name => "idx_group_widget_fingerprint"

  create_table "locations", :force => true do |t|
    t.integer  "fipsid",                     :null => false
    t.integer  "entrytype",                  :null => false
    t.string   "name",                       :null => false
    t.string   "abbreviation", :limit => 10, :null => false
    t.string   "office_link"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "locations", ["name"], :name => "idx_locations_on_name", :unique => true

  create_table "notification_exceptions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "question_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "notification_exceptions", ["user_id", "question_id"], :name => "idx_connection", :unique => true

  create_table "notifications", :force => true do |t|
    t.integer  "notifiable_id"
    t.string   "notifiable_type",   :limit => 30
    t.integer  "created_by",                                         :null => false
    t.integer  "recipient_id",                                       :null => false
    t.text     "additional_data"
    t.boolean  "processed",                       :default => false, :null => false
    t.integer  "notification_type",                                  :null => false
    t.datetime "delivery_time",                                      :null => false
    t.integer  "offset",                          :default => 0
    t.integer  "delayed_job_id"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
  end

  create_table "question_events", :force => true do |t|
    t.integer  "question_id",                        :null => false
    t.integer  "submitter_id"
    t.integer  "initiated_by_id"
    t.integer  "recipient_id"
    t.text     "response"
    t.integer  "event_state",                        :null => false
    t.integer  "contributing_question_id"
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
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "question_events", ["contributing_question_id"], :name => "idx_contributing_question_id"
  add_index "question_events", ["created_at", "event_state", "previous_handling_recipient_id"], :name => "idx_handling"
  add_index "question_events", ["initiated_by_id"], :name => "idx_initiated_by"
  add_index "question_events", ["question_id"], :name => "idx_question_id"
  add_index "question_events", ["recipient_id"], :name => "idx_recipient_id"
  add_index "question_events", ["submitter_id"], :name => "idx_submitter_id"

  create_table "questions", :force => true do |t|
    t.integer  "current_resolver_id"
    t.integer  "contributing_question_id"
    t.string   "status",                   :default => "",    :null => false
    t.text     "body",                                        :null => false
    t.string   "title"
    t.boolean  "is_private",               :default => false
    t.integer  "is_private_reason"
    t.integer  "assignee_id"
    t.integer  "assigned_group_id"
    t.boolean  "duplicate",                :default => false, :null => false
    t.string   "external_app_id"
    t.string   "submitter_email"
    t.datetime "resolved_at"
    t.datetime "question_updated_at"
    t.text     "current_response"
    t.string   "current_resolver_email"
    t.string   "question_fingerprint",                        :null => false
    t.string   "submitter_firstname",      :default => "",    :null => false
    t.string   "submitter_lastname",       :default => "",    :null => false
    t.integer  "county_id"
    t.integer  "location_id"
    t.boolean  "spam",                     :default => false, :null => false
    t.string   "user_ip",                  :default => "",    :null => false
    t.string   "user_agent",               :default => "",    :null => false
    t.string   "referrer",                 :default => "",    :null => false
    t.string   "group_name"
    t.integer  "status_state",                                :null => false
    t.string   "zip_code"
    t.integer  "original_group_id"
    t.integer  "submitter_id",             :default => 0
    t.datetime "last_assigned_at"
    t.datetime "last_opened_at",                              :null => false
    t.boolean  "is_api"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "questions", ["assigned_group_id"], :name => "fk_group_assignee"
  add_index "questions", ["assignee_id"], :name => "fk_assignee"
  add_index "questions", ["contributing_question_id"], :name => "fk_contributing_question"
  add_index "questions", ["county_id"], :name => "fk_question_county"
  add_index "questions", ["created_at"], :name => "created_at_idx"
  add_index "questions", ["current_resolver_id"], :name => "fk_current_resolver"
  add_index "questions", ["group_name"], :name => "group_name_idx"
  add_index "questions", ["is_private"], :name => "fk_is_private"
  add_index "questions", ["location_id"], :name => "fk_question_location"
  add_index "questions", ["original_group_id"], :name => "fk_original_group_id"
  add_index "questions", ["question_fingerprint"], :name => "question_fingerprint_idx"
  add_index "questions", ["resolved_at"], :name => "resolved_at_idx"
  add_index "questions", ["status_state"], :name => "status_state_idx"
  add_index "questions", ["submitter_id"], :name => "submitter_id_idx"

  create_table "ratings", :force => true do |t|
    t.integer  "rateable_id",   :null => false
    t.string   "rateable_type", :null => false
    t.integer  "score",         :null => false
    t.integer  "user_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "responses", :force => true do |t|
    t.integer  "resolver_id"
    t.integer  "submitter_id"
    t.integer  "question_id",                                 :null => false
    t.text     "body",                                        :null => false
    t.integer  "duration_since_last",                         :null => false
    t.boolean  "sent",                     :default => false, :null => false
    t.integer  "contributing_question_id"
    t.text     "signature"
    t.string   "user_ip"
    t.string   "user_agent"
    t.string   "referrer"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "responses", ["contributing_question_id"], :name => "idx_contributing_question"
  add_index "responses", ["question_id"], :name => "idx_question_id"
  add_index "responses", ["resolver_id"], :name => "idx_resolver_id"
  add_index "responses", ["submitter_id"], :name => "idx_submitter_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "taggingindex", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
  end

  add_index "tags", ["name"], :name => "idx_tags_on_name", :unique => true

  create_table "user_counties", :force => true do |t|
    t.integer "county_id", :default => 0, :null => false
    t.integer "user_id",   :default => 0, :null => false
  end

  add_index "user_counties", ["user_id", "county_id"], :name => "fk_counties_users", :unique => true

  create_table "user_locations", :force => true do |t|
    t.integer "location_id", :default => 0, :null => false
    t.integer "user_id",     :default => 0, :null => false
  end

  add_index "user_locations", ["user_id", "location_id"], :name => "fk_locations_users", :unique => true

  create_table "user_preferences", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "name",       :null => false
    t.text     "setting",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_preferences", ["user_id"], :name => "fk_user_prefs_user_id"

  create_table "users", :force => true do |t|
    t.integer  "darmok_id"
    t.string   "kind",                                    :default => "",    :null => false
    t.string   "login",                    :limit => 80
    t.string   "name"
    t.string   "email"
    t.string   "title"
    t.integer  "position_id"
    t.integer  "location_id",                             :default => 0
    t.integer  "county_id",                               :default => 0
    t.boolean  "retired",                                 :default => false
    t.boolean  "is_admin",                                :default => false
    t.string   "phone_number"
    t.boolean  "aae_responder",                           :default => true
    t.string   "time_zone"
    t.boolean  "is_question_wrangler",                    :default => false
    t.datetime "vacated_aae_at"
    t.boolean  "first_aae_away_reminder",                 :default => false
    t.boolean  "second_aae_away_reminder",                :default => false
    t.string   "bio"
    t.boolean  "is_blocked",                              :default => false, :null => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "encrypted_password",       :limit => 128
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                           :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
  end

  add_index "users", ["email"], :name => "email"
  add_index "users", ["login"], :name => "login"
  add_index "users", ["retired"], :name => "retired"

end
