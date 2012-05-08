class CreateGroupEvents < ActiveRecord::Migration
  def change
    create_table :group_events do |t|
      t.integer :created_by
      t.string  :description
      t.integer :event_code
      t.timestamps
    end
    
    add_index :group_events, ["created_by"], :name => "idx_group_events_created_by"
  end
end
