class AddRefererTracks < ActiveRecord::Migration
  def change
    create_table "referer_tracks", :force => true do |t|
      t.string   "ipaddr"
      t.text     "referer"
      t.string   "landing_page"
      t.text     "user_agent"
      t.integer  "load_count",         :default => 1, :null => false
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
    end

    create_table "location_tracks", :force => true do |t|
      t.string   "ipaddr"
      t.integer  "referer_track_id"
      t.integer  "location_id"
      t.integer  "group_count"
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
    end

    add_index "location_tracks", [:referer_track_id, :location_id], :name => "association_ndx"

    create_table "ask_tracks", :force => true do |t|
      t.string   "ipaddr"
      t.integer  "referer_track_id"
      t.integer  "location_track_id"
      t.integer  "group_id"
      t.boolean  "group_active"
      t.integer  "question_id"
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
    end

    add_index "ask_tracks", [:referer_track_id, :location_track_id, :group_id, :question_id], :name => "association_ndx"

  end
end
