class CreateExpertiseLocations < ActiveRecord::Migration
  def change
    create_table :expertise_locations do |t|
      t.integer "fipsid",                     :null => false
      t.integer "entrytype",                  :null => false
      t.string  "name",                       :null => false
      t.string  "abbreviation", :limit => 10, :null => false
      t.timestamps
    end
    
    add_index "expertise_locations", ["name"], :name => "idx_expertise_locations_on_name", :unique => true
    
    create_table :expertise_locations_users, :id => false do |t|
      t.integer "expertise_location_id", :default => 0, :null => false
      t.integer "user_id",               :default => 0, :null => false
    end

    add_index "expertise_locations_users", ["user_id", "expertise_location_id"], :name => "fk_locations_users", :unique => true
  end
end
