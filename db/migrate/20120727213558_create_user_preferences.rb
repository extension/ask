class CreateUserPreferences < ActiveRecord::Migration
  def change
    create_table :user_preferences do |t|
      t.integer :user_id, :null => false
      t.string  :name, :null => false
      t.text    :setting, :null => false  
      t.timestamps
    end
    
    add_index :user_preferences, ["user_id"], :name => "fk_user_prefs_user_id"
  end
end
