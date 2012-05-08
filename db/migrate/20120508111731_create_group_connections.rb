class CreateGroupConnections < ActiveRecord::Migration
  def change
    create_table :group_connections do |t|
      t.integer :user_id, :null => false
      t.integer :group_id, :null => false
      t.string  :connection_type, :null => false
      t.integer :connection_code, :null => false
      t.boolean :send_notifications, :default => 1
      t.integer :connected_by
      t.timestamps
    end
    
    add_index :group_connections, ['connection_type'], :name => 'idx_group_connections_on_connection_type'
    add_index :group_connections, ['user_id', 'group_id'], :name => 'fk_user_group', :unique => true
  end
end
