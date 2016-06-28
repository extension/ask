class AddAssignmentLog < ActiveRecord::Migration
  def change
    create_table "auto_assignment_logs", :force => true do |t|
      t.integer  "question_id"
      t.integer  "user_id"
      t.integer  "group_id"
      t.integer  "question_location_id"
      t.integer  "question_county_id"
      t.integer  "pool_floor"
      t.integer  "group_member_count"
      t.integer  "group_present_count"
      t.integer  "wrangler_assignment_code"
      t.integer  "assignment_code"
      t.text     "assignee_tests"
      t.text     "user_pool",     :limit => 16777215
      t.datetime "created_at",    :null => false
    end

    add_column(:question_events, :auto_assignment_log_id, :integer)

  end
end
