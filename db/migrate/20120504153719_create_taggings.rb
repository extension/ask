class CreateTaggings < ActiveRecord::Migration
  def change
    create_table :taggings do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.timestamps
    end
    add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "taggingindex", :unique => true
  end
end
