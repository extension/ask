class AddAssignmentLog < ActiveRecord::Migration
  def change
    create_table "auto_assignment_logs", :force => true do |t|
      t.integer  "question_id"
      t.integer  "user_id"
      t.integer  "group_id"
      t.integer  "pool_floor"
      t.text     "reason"
      t.text     "pool",     :limit => 16777215
      t.datetime "created_at",                       :null => false
    end
  end
end
