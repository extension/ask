class CreateGeoNames < ActiveRecord::Migration
  def change
    create_table "geo_names", :force => true do |t|
        t.string  "feature_name",       :limit => 121
        t.string  "feature_class",      :limit => 51
        t.string  "state_alpha",        :limit => 3
        t.string  "county_name",        :limit => 101
        t.float   "prim_lat_dec",       :limit => 8
        t.float   "prim_long_dec",      :limit => 8
        t.string  "map_name"
        t.string  "date_created"
        t.string  "date_edited"
    end
    
    add_index "geo_names", ["feature_name","state_alpha","county_name"], :name => 'name_state_county_ndx'
  end

end
