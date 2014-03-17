class AddDownloads < ActiveRecord::Migration

  def change

      create_table "downloads", :force => true do |t|
        t.string   "label"
        t.string   "display_label"
        t.string   "filterclass"
        t.integer  "filter_id"
        t.boolean  "dump_in_progress",        :default => false
        t.datetime "last_generated_at"
        t.float    "last_runtime"
        t.integer  "last_filesize"
        t.integer  "last_itemcount"
        t.text     "notifylist"
        t.timestamps
      end

      add_index "downloads", ["label","filterclass","filter_id"], :name => "download_ndx"

      create_table "download_logs", :force => true do |t|
        t.integer  "download_id"
        t.integer  "downloaded_by"
        t.datetime "created_at"
      end

      add_index "download_logs", ["download_id","downloaded_by"], :name => "download_ndx"


  end

end
