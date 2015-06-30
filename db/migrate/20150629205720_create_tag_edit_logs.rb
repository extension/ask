class CreateTagEditLogs < ActiveRecord::Migration
  def change
    create_table :tag_edit_logs do |t|
      t.integer :user_id
      t.integer :activitycode
      t.text :description
      t.text :affected

      t.timestamps
    end
  end
end
