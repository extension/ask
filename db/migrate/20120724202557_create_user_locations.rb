class CreateUserLocations < ActiveRecord::Migration
  def change
    create_table :user_locations do |t|
      t.integer "location_id", :default => 0, :null => false
      t.integer "user_id", :default => 0, :null => false
    end

    add_index "user_locations", ["user_id", "location_id"], :name => "fk_locations_users", :unique => true
  end
end
