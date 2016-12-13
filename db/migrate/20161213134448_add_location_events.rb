class AddLocationEvents < ActiveRecord::Migration
  def change
    create_table "location_events", :force => true do |t|
      t.integer  "location_id"
      t.integer  "created_by",           :null => false
      t.integer  "event_code"
      t.text     "additionaldata"
      t.datetime "created_at",           :null => false
      t.datetime "updated_at",           :null => false
    end

    add_index "location_events", ["location_id","created_by","event_code"], :name => "idx_who_where_what"

  end
end
