class AddOriginalLocationAndCounty < ActiveRecord::Migration
  def change 
    add_column :questions, :original_location_id, :integer, :null => true
    add_column :questions, :original_county_id, :integer, :null => true
    
    execute("UPDATE questions AS q SET q.original_location_id = q.location_id, q.original_county_id = q.county_id")
  end
end
