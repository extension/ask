class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string  :name, :null => false
      t.text    :description
      t.boolean :active, :default => 1
      t.integer :created_by, :null => false
      t.integer :widget_id
      t.string  :widget_fingerprint
      t.boolean :widget_upload_capable
      t.boolean :widget_show_location
      t.boolean :widget_enable_tags
      t.integer :widget_location_id
      t.integer :widget_county_id
      t.string  :old_widget_url
      t.boolean :group_notify, :default => 0
      t.integer :creator_id, :null => false  
      t.timestamps
    end
    
    add_index :groups, ["name"], :name => "idx_group_name", :unique => true
    add_index :groups, ["widget_id"], :name => "idx_group_widget_id"
  end
end
