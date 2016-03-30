class AddIndexes < ActiveRecord::Migration
  def change
    add_index "assets", ["type", "assetable_id", "assetable_type"], :name => "assetable_ndx"
    remove_index "questions", :name => "fk_is_private"
    add_index "questions", ["is_private", "created_at"], :name => "private_flag_ndx"
  end
end
