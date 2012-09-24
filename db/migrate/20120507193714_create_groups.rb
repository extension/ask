class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string  :name, :null => false
      t.text    :description
      t.boolean :widget_public_option, :default => 1
      t.boolean :active, :default => 1
      t.boolean :assignment_outside_locations, :default => 1
      t.boolean :individual_assignment, :default => 1
      t.integer :created_by, :null => false
      t.string  :widget_fingerprint
      t.boolean :widget_upload_capable
      t.boolean :widget_show_location
      t.boolean :widget_show_title
      t.boolean :widget_enable_tags
      t.integer :widget_location_id
      t.integer :widget_county_id
      t.string  :old_widget_url
      t.boolean :group_notify, :default => 0
      t.integer :darmok_expertise_id, :null => true, :default => nil
      t.timestamps
    end
    
    add_index :groups, ["name"], :name => "idx_group_name", :unique => true
    add_index :groups, ["widget_fingerprint"], :name => "idx_group_widget_fingerprint"
  end
end
