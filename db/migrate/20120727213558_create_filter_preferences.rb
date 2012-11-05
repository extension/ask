class CreateFilterPreferences < ActiveRecord::Migration
  def change
    create_table :filter_preferences do |t|
      t.integer :user_id, :null => false
      t.text    :setting, :null => false  
      t.timestamps
    end
    
    add_index :filter_preferences, ["user_id"], :name => "fk_filter_prefs_user_id"
  end
end
