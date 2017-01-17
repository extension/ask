class AddLocationMessage < ActiveRecord::Migration
  def change

    create_table "location_messages", :force => true do |t|
      t.integer  "location_id",            :null => false
      t.integer  "edited_by",            :null => false
      t.text     "message",            :null => false
      t.timestamps
    end

    add_index "location_messages", ["location_id","edited_by"], :name => "idx_who_where"


  end

  def down
  end
end
