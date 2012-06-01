class CreateGroupEvents < ActiveRecord::Migration
  def change
    create_table :group_events do |t|
      t.integer :created_by, :null => false
      t.integer :recipient_id
      t.string  :description
      t.integer :event_code
      t.integer :group_id, :null => false
      t.timestamps
    end
    
    add_index :group_events, ["created_by"], :name => "idx_group_events_created_by"
    add_index :group_events, ["group_id"], :name => "idx_group_events_group_id"
    add_index :group_events, ["recipient_id"], :name => "idx_group_events_recipient_id"
  end
end
