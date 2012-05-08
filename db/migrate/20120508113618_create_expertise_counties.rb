class CreateExpertiseCounties < ActiveRecord::Migration
  def change
    create_table :expertise_counties do |t|
      t.integer "fipsid",                             :null => false
      t.integer "expertise_location_id",              :null => false
      t.integer "state_fipsid",                       :null => false
      t.string  "countycode",            :limit => 3, :null => false
      t.string  "name",                               :null => false
      t.string  "censusclass",           :limit => 2, :null => false
      t.timestamps
    end
    
    add_index "expertise_counties", ["expertise_location_id"], :name => "idx_expertise_counties_on_location_id"
    add_index "expertise_counties", ["name"], :name => "idx_expertise_counties_on_name"
    
    create_table "expertise_counties_users", :id => false do |t|
      t.integer "expertise_county_id", :default => 0, :null => false
      t.integer "user_id",             :default => 0, :null => false
    end

    add_index "expertise_counties_users", ["user_id", "expertise_county_id"], :name => "fk_counties_users", :unique => true
  end
end
