class AddDownloads < ActiveRecord::Migration

  def change

      create_table "downloads", :force => true do |t|
        t.string   "label"
        t.string   "display_label"
        t.string   "filetype"
        t.string   "objectclass"
        t.string   "objectmethod"
        t.string   "filterclass"
        t.integer  "filter_id"
        t.integer  "period",             :default => 0
        t.boolean  "in_progress",        :default => false
        t.boolean  "is_private",         :default => false
        t.datetime "last_generated_at"
        t.float    "last_runtime"
        t.integer  "last_filesize"
        t.text     "notifylist"
        t.timestamps
      end

      add_index "downloads", ["label", "period"], :name => "download_ndx"


  end

end
