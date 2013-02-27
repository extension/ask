class CreateUserEvents < ActiveRecord::Migration
  def change
    create_table :user_events do |t|
      t.integer :user_id, :null => false
      t.integer :created_by, :null => false
      t.integer :event_code, :null => false
      t.string  :description, :null => false
      t.text    :updated_user_attributes
      t.timestamps
    end
    
    add_index :user_events, :user_id, :name => 'user_event_user_id'
  end
end

