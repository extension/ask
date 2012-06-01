class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer  "notifiable_id"
      t.string   "notifiable_type",  :limit => 30
      t.integer  "created_by", :null => false
      t.integer  "recipient_id", :null => false
      t.text     "additional_data"
      t.boolean  "processed",                      :default => false, :null => false
      t.integer  "notification_type",                                 :null => false
      t.datetime "delivery_time",                                     :null => false
      t.integer  "offset",                         :default => 0
      t.integer  "delayed_job_id"
      t.timestamps
    end
  end
end
