class CreateCounties < ActiveRecord::Migration
  def change
    create_table :counties do |t|
      t.integer "fipsid",                             :null => false
      t.integer "location_id",              :null => false
      t.integer "state_fipsid",                       :null => false
      t.string  "countycode",            :limit => 3, :null => false
      t.string  "name",                               :null => false
      t.string  "censusclass",           :limit => 2, :null => false
      t.timestamps
    end
    
    add_index "counties", ["location_id"], :name => "idx_counties_on_location_id"
    add_index "counties", ["name"], :name => "idx_counties_on_name"
  end
end
