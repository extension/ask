class CreateNotificationExceptions < ActiveRecord::Migration
  def change
    create_table :notification_exceptions do |t|
      t.integer  "user_id"
      t.integer  "question_id"
      t.timestamps
    end
    
    add_index "notification_exceptions", ["user_id", "question_id"], :name => "idx_connection", :unique => true
  end
end
