class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer "fipsid",                     :null => false
      t.integer "entrytype",                  :null => false
      t.string  "name",                       :null => false
      t.string  "abbreviation", :limit => 10, :null => false
      t.string  "office_link"
      t.timestamps
    end
    
    add_index "locations", ["name"], :name => "idx_locations_on_name", :unique => true
  end
end
