# === COPYRIGHT:
# Copyright (c) North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# see LICENSE file

class CreateUsers < ActiveRecord::Migration
  def change 
    create_table "users" do |t|
      t.integer  "darmok_id"
      t.string   "type",                                   :default => "",    :null => false
      t.string   "login",                    :limit => 80
      t.string   "name"
      t.string   "email",                    :limit => 96
      t.string   "title"
      t.string   "position"
      t.integer  "location_id",                            :default => 0
      t.integer  "county_id",                              :default => 0
      t.boolean  "retired",                                :default => false
      t.boolean  "is_admin",                               :default => false
      t.string   "phonenumber"
      t.boolean  "aae_responder",                          :default => true
      t.string   "time_zone"
      t.boolean  "is_question_wrangler",                   :default => false
      t.datetime "vacated_aae_at"
      t.boolean  "first_aae_away_reminder",                :default => false
      t.boolean  "second_aae_away_reminder",               :default => false
      t.string   "bio"
      # paperclip method for generating necessary image columns
      t.has_attached_file :avatar
      
      # devise stuff
      # creates :encrypted_password field (string) 
      # we are letting these fields be null to cover certain cases of user records like twitter authentication via oauth
      # that does not give us an email address and we're not storing a pw for it
      t.database_authenticatable :null => true
      # does not create :remember_token(string), not sure why right now, default is supposed to create it
      # creates :remember_created_at(Datetime)
      t.rememberable
      # creates :sign_in_count (Integer)
      # creates :current_sign_in_at (Datetime)
      # creates :last_sign_in_at (Datetime)
      # creates :current_sign_in_ip (string)
      # creates :last_sign_in_ip (string)
      t.trackable
      
      
      t.timestamps
    end

    add_index "users", ["email"], :name => "email"
    add_index "users", ["login"], :name => "login"
    add_index "users", ["retired"], :name => "retired"  
  end
end
