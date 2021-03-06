class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string   "name"
      t.datetime "created_at"
    end
    add_index "tags", ["name"], :name => "idx_tags_on_name", :unique => true
  end
end


