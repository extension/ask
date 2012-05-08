class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer  "notifiable_id"
      t.string   "notifiable_type",  :limit => 30
      t.boolean  "processed",                      :default => false, :null => false
      t.integer  "notificationtype",                                  :null => false
      t.datetime "delivery_time",                                     :null => false
      t.integer  "offset",                         :default => 0
      t.integer  "delayed_job_id"
      t.timestamps
    end
  end
end
