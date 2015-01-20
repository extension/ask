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

ActiveRecord::Schema.define(:version => 20150108161507) do

  create_table "activity_logs", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.integer  "loggable_id"
    t.string   "loggable_type", :limit => 30
    t.integer  "ipaddr"
    t.text     "additional"
    t.datetime "created_at"
  end

  add_index "activity_logs", ["user_id", "loggable_id", "loggable_type"], :name => "activity_ndx"

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

  create_table "demographic_logs", :force => true do |t|
    t.integer  "demographic_id",  :null => false
    t.text     "changed_answers"
    t.datetime "created_at"
  end

  add_index "demographic_logs", ["demographic_id"], :name => "log_ndx"

  create_table "demographic_questions", :force => true do |t|
    t.boolean  "is_active",     :default => true
    t.text     "prompt"
    t.integer  "questionorder"
    t.string   "responsetype"
    t.text     "responses"
    t.integer  "range_start"
    t.integer  "range_end"
    t.integer  "creator_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "demographics", :force => true do |t|
    t.integer  "demographic_question_id", :null => false
    t.integer  "user_id",                 :null => false
    t.text     "response"
    t.integer  "value"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "demographics", ["demographic_question_id", "user_id"], :name => "dq_u_ndx", :unique => true

  create_table "download_logs", :force => true do |t|
    t.integer  "download_id"
    t.integer  "downloaded_by"
    t.datetime "created_at"
  end

  add_index "download_logs", ["download_id", "downloaded_by"], :name => "download_ndx"

  create_table "downloads", :force => true do |t|
    t.string   "label"
    t.string   "display_label"
    t.string   "filterclass"
    t.integer  "filter_id"
    t.boolean  "dump_in_progress",  :default => false
    t.datetime "last_generated_at"
    t.float    "last_runtime"
    t.integer  "last_filesize"
    t.integer  "last_itemcount"
    t.text     "notifylist"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "downloads", ["label", "filterclass", "filter_id"], :name => "download_ndx"

  create_table "evaluation_answers", :force => true do |t|
    t.integer  "evaluation_question_id",              :null => false
    t.integer  "user_id",                             :null => false
    t.integer  "question_id",                         :null => false
    t.text     "response"
    t.integer  "value",                  :limit => 8
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "evaluation_answers", ["evaluation_question_id", "user_id", "question_id"], :name => "eq_u_q_ndx", :unique => true

  create_table "evaluation_logs", :force => true do |t|
    t.integer  "evaluation_answer_id", :null => false
    t.text     "changed_answers"
    t.datetime "created_at"
  end

  add_index "evaluation_logs", ["evaluation_answer_id"], :name => "log_ndx"

  create_table "evaluation_questions", :force => true do |t|
    t.boolean  "is_active",     :default => true
    t.text     "prompt"
    t.integer  "questionorder"
    t.string   "responsetype"
    t.text     "responses"
    t.integer  "range_start"
    t.integer  "range_end"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "filter_preferences", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.text     "setting",    :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "filter_preferences", ["user_id"], :name => "fk_filter_prefs_user_id"

  create_table "geo_names", :force => true do |t|
    t.string  "feature_name",       :limit => 121
    t.string  "feature_class",      :limit => 51
    t.string  "state_abbreviation", :limit => 3
    t.string  "state_code",         :limit => 3
    t.string  "county",             :limit => 101
    t.string  "county_code",        :limit => 4
    t.string  "lat_dms",            :limit => 8
    t.string  "long_dms",           :limit => 9
    t.float   "lat"
    t.float   "long"
    t.string  "source_lat_dms",     :limit => 8
    t.string  "source_long_dms",    :limit => 9
    t.float   "source_lat"
    t.float   "source_long"
    t.integer "elevation"
    t.string  "map_name"
    t.string  "create_date_txt"
    t.string  "edit_date_txt"
    t.date    "create_date"
    t.date    "edit_date"
  end

  add_index "geo_names", ["feature_name", "state_abbreviation", "county"], :name => "name_state_county_ndx"

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
    t.integer  "created_by",           :null => false
    t.integer  "recipient_id"
    t.string   "description"
    t.integer  "event_code"
    t.integer  "group_id",             :null => false
    t.text     "updated_group_values"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
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
    t.boolean  "widget_public_option",         :default => false
    t.boolean  "widget_active",                :default => true
    t.boolean  "assignment_outside_locations", :default => true
    t.boolean  "individual_assignment",        :default => true
    t.integer  "created_by",                                      :null => false
    t.boolean  "is_test",                      :default => false
    t.string   "widget_fingerprint"
    t.boolean  "widget_upload_capable",        :default => false
    t.boolean  "widget_show_location",         :default => false
    t.boolean  "widget_show_title",            :default => false
    t.boolean  "widget_enable_tags",           :default => false
    t.integer  "widget_location_id"
    t.integer  "widget_county_id"
    t.integer  "old_widget_id"
    t.string   "old_widget_url"
    t.boolean  "group_notify",                 :default => false
    t.integer  "darmok_expertise_id"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.boolean  "group_active",                 :default => true,  :null => false
    t.boolean  "ignore_county_routing",        :default => false
    t.boolean  "ask_form_show_location",       :default => true
    t.boolean  "send_evaluation",              :default => true
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

  create_table "mailer_caches", :force => true do |t|
    t.string   "hashvalue",      :limit => 40,                      :null => false
    t.integer  "user_id"
    t.integer  "cacheable_id"
    t.string   "cacheable_type", :limit => 30
    t.integer  "open_count",                         :default => 0
    t.text     "markup",         :limit => 16777215
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
  end

  add_index "mailer_caches", ["hashvalue"], :name => "hashvalue_ndx"
  add_index "mailer_caches", ["user_id", "open_count"], :name => "open_learner_ndx"

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

  create_table "old_evaluation_answers", :force => true do |t|
    t.integer  "evaluation_question_id", :null => false
    t.integer  "user_id",                :null => false
    t.integer  "question_id",            :null => false
    t.text     "response"
    t.integer  "value"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "old_evaluation_answers", ["evaluation_question_id", "user_id", "question_id"], :name => "eq_u_q_ndx", :unique => true

  create_table "preferences", :force => true do |t|
    t.integer  "prefable_id"
    t.integer  "group_id"
    t.integer  "question_id"
    t.string   "prefable_type",  :limit => 30
    t.string   "classification"
    t.string   "name",                         :null => false
    t.string   "datatype"
    t.string   "value"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "preferences", ["classification"], :name => "index_preferences_on_classification"
  add_index "preferences", ["prefable_id", "prefable_type", "name", "group_id", "question_id"], :name => "pref_uniq_ndx", :unique => true

  create_table "question_data_caches", :force => true do |t|
    t.integer  "question_id"
    t.text     "data_values"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "version",     :default => 1
  end

  add_index "question_data_caches", ["question_id"], :name => "question_ndx", :unique => true

  create_table "question_events", :force => true do |t|
    t.integer  "question_id",                                           :null => false
    t.integer  "submitter_id"
    t.integer  "initiated_by_id"
    t.integer  "recipient_id"
    t.integer  "recipient_group_id"
    t.text     "response"
    t.integer  "event_state",                                           :null => false
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
    t.integer  "previous_group_id"
    t.integer  "changed_group_id"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
    t.text     "updated_question_values"
    t.boolean  "is_extension",                       :default => false
    t.string   "changed_tag"
  end

  add_index "question_events", ["contributing_question_id"], :name => "idx_contributing_question_id"
  add_index "question_events", ["created_at", "event_state", "previous_handling_recipient_id"], :name => "idx_handling"
  add_index "question_events", ["event_state"], :name => "index_question_events_on_event_state"
  add_index "question_events", ["initiated_by_id"], :name => "idx_initiated_by"
  add_index "question_events", ["question_id"], :name => "idx_question_id"
  add_index "question_events", ["recipient_id"], :name => "idx_recipient_id"
  add_index "question_events", ["submitter_id"], :name => "idx_submitter_id"

  create_table "question_filters", :force => true do |t|
    t.integer  "created_by"
    t.text     "settings"
    t.string   "fingerprint", :limit => 40
    t.integer  "use_count"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "question_filters", ["fingerprint"], :name => "fingerprint_ndx", :unique => true

  create_table "question_viewlogs", :force => true do |t|
    t.integer  "user_id",                    :null => false
    t.integer  "question_id"
    t.integer  "activity"
    t.integer  "view_count",  :default => 1, :null => false
    t.datetime "updated_at"
  end

  add_index "question_viewlogs", ["user_id", "question_id", "activity"], :name => "activity_uniq_ndx", :unique => true

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
    t.integer  "initial_response_id"
    t.integer  "initial_response_time"
    t.datetime "initial_response_at"
    t.integer  "initial_responder_id"
    t.string   "question_fingerprint",                        :null => false
    t.string   "submitter_firstname",      :default => ""
    t.string   "submitter_lastname",       :default => ""
    t.integer  "county_id"
    t.integer  "location_id"
    t.boolean  "spam_legacy",              :default => false, :null => false
    t.string   "user_ip",                  :default => "",    :null => false
    t.text     "user_agent"
    t.text     "referrer"
    t.integer  "status_state",                                :null => false
    t.string   "zip_code"
    t.integer  "original_group_id"
    t.integer  "submitter_id",             :default => 0
    t.datetime "last_assigned_at"
    t.datetime "last_opened_at",                              :null => false
    t.boolean  "is_api"
    t.boolean  "evaluation_sent",          :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "original_location_id"
    t.integer  "original_county_id"
    t.datetime "working_on_this"
    t.boolean  "featured",                 :default => false, :null => false
    t.datetime "featured_at"
    t.boolean  "submitter_is_extension",   :default => false
    t.text     "widget_parent_url"
  end

  add_index "questions", ["assigned_group_id"], :name => "fk_group_assignee"
  add_index "questions", ["assignee_id"], :name => "fk_assignee"
  add_index "questions", ["contributing_question_id"], :name => "fk_contributing_question"
  add_index "questions", ["county_id"], :name => "fk_question_county"
  add_index "questions", ["created_at"], :name => "created_at_idx"
  add_index "questions", ["current_resolver_id"], :name => "fk_current_resolver"
  add_index "questions", ["evaluation_sent"], :name => "evaluation_flag_ndx"
  add_index "questions", ["initial_response_id", "initial_response_time", "initial_response_at", "initial_responder_id"], :name => "initial_response_ndx"
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
    t.boolean  "sent",                     :default => false, :null => false
    t.integer  "contributing_question_id"
    t.text     "signature"
    t.string   "user_ip"
    t.string   "user_agent"
    t.string   "referrer"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.boolean  "is_expert"
    t.boolean  "previous_expert"
    t.integer  "time_since_submission"
    t.integer  "time_since_last"
  end

  add_index "responses", ["contributing_question_id"], :name => "idx_contributing_question"
  add_index "responses", ["is_expert", "previous_expert"], :name => "resonse_type_ndx"
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

  create_table "user_events", :force => true do |t|
    t.integer  "user_id",                 :null => false
    t.integer  "created_by",              :null => false
    t.integer  "event_code",              :null => false
    t.string   "description",             :null => false
    t.text     "updated_user_attributes"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "user_events", ["user_id"], :name => "user_event_user_id"

  create_table "user_locations", :force => true do |t|
    t.integer "location_id", :default => 0, :null => false
    t.integer "user_id",     :default => 0, :null => false
  end

  add_index "user_locations", ["user_id", "location_id"], :name => "fk_locations_users", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "darmok_id"
    t.string   "kind",                                    :default => "",         :null => false
    t.string   "login",                    :limit => 80
    t.string   "first_name"
    t.string   "last_name"
    t.string   "public_name"
    t.string   "email"
    t.string   "title"
    t.integer  "position_id"
    t.integer  "location_id",                             :default => 0
    t.integer  "county_id",                               :default => 0
    t.boolean  "retired",                                 :default => false
    t.boolean  "is_admin",                                :default => false
    t.boolean  "auto_route",                              :default => true,       :null => false
    t.string   "phone_number"
    t.boolean  "away",                                    :default => false
    t.string   "time_zone"
    t.boolean  "is_question_wrangler",                    :default => false
    t.datetime "vacated_aae_at"
    t.boolean  "first_aae_away_reminder",                 :default => false
    t.boolean  "second_aae_away_reminder",                :default => false
    t.text     "bio"
    t.boolean  "is_blocked",                              :default => false,      :null => false
    t.text     "signature"
    t.string   "routing_instructions",                    :default => "anywhere", :null => false
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
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.date     "last_active_at"
    t.boolean  "needs_search_update"
    t.boolean  "has_invalid_email",                       :default => false
    t.string   "invalid_email"
  end

  add_index "users", ["darmok_id"], :name => "people_id_ndx"
  add_index "users", ["email"], :name => "email"
  add_index "users", ["login"], :name => "login"
  add_index "users", ["needs_search_update"], :name => "search_update_flag_ndx"
  add_index "users", ["retired"], :name => "retired"
  add_index "users", ["routing_instructions"], :name => "routing_instructions"

  create_table "versions", :force => true do |t|
    t.string   "item_type",                           :null => false
    t.integer  "item_id",                             :null => false
    t.string   "event",                               :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.string   "ip_address"
    t.datetime "created_at"
    t.text     "object_changes"
    t.text     "reason"
    t.boolean  "notify_submitter", :default => false, :null => false
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

  create_table "widget_logs", :force => true do |t|
    t.string   "referrer_host"
    t.text     "referrer_url"
    t.string   "base_widget_url"
    t.string   "widget_url"
    t.string   "widget_fingerprint"
    t.integer  "load_count",         :default => 0, :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  create_table "yo_los", :force => true do |t|
    t.integer  "user_id",              :default => 0
    t.string   "ipaddress"
    t.integer  "detected_location_id", :default => 0
    t.integer  "detected_county_id",   :default => 0
    t.integer  "location_id",          :default => 0
    t.integer  "county_id",            :default => 0
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "yo_los", ["user_id"], :name => "user_ndx"

end
