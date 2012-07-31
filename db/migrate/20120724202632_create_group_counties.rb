class CreateGroupCounties < ActiveRecord::Migration
  def change
    create_table "group_counties" do |t|
      t.integer "county_id", :default => 0, :null => false
      t.integer "group_id", :default => 0, :null => false
    end
    
    add_index "group_counties", ["group_id", "county_id"], :name => "fk_counties_groups", :unique => true
  end
end
