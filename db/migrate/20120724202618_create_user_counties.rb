class CreateUserCounties < ActiveRecord::Migration
  def change
    create_table "user_counties" do |t|
      t.integer "county_id", :default => 0, :null => false
      t.integer "user_id",  :default => 0, :null => false
    end
    
    add_index "user_counties", ["user_id", "county_id"], :name => "fk_counties_users", :unique => true
  end
end
