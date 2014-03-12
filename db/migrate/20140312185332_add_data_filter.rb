class AddDataFilter < ActiveRecord::Migration
  def change

    create_table "data_filters", :force => true do |t|
      t.integer  "created_by"
      t.text     "settings"
      t.text     "notifylist"
      t.string   "fingerprint", :limit => 40
      t.boolean  "dump_in_progress"
      t.datetime "dump_last_generated_at"
      t.float    "dump_last_runtime"
      t.integer  "dump_last_filesize"
      t.timestamps
    end

    add_index "data_filters", ["fingerprint"], :name => "fingerprint_ndx", :unique => true

    DataFilter.reset_column_information
    DataFilter.create(settings: {}, created_by: User.system_user_id)

  end
end
