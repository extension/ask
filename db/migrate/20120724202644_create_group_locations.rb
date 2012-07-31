class CreateGroupLocations < ActiveRecord::Migration
  def change
    create_table :group_locations do |t|
      t.integer "location_id", :default => 0, :null => false
      t.integer "group_id", :default => 0, :null => false
    end

    add_index "group_locations", ["group_id", "location_id"], :name => "fk_locations_groups", :unique => true
  end
end
