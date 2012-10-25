class AddYoLo < ActiveRecord::Migration
  def change
    create_table "yo_los", :force => true do |t|
      t.integer 'user_id', default: 0
      t.string  'ipaddress'
      t.integer 'detected_location_id', default: 0
      t.integer 'detected_county_id', default: 0
      t.integer 'location_id', default: 0
      t.integer 'county_id', default: 0
      t.timestamps
    end
  end

end
