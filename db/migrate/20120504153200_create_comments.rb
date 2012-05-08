class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text     "content",                           :null => false
      t.string   "ancestry"
      t.integer  "user_id",                        :null => false
      t.integer  "question_id",                          :null => false
      t.boolean  "parent_removed", :default => false
      t.timestamps
    end
    
    add_index "comments", ["ancestry"], :name => "idx_comments_on_ancestry"
    add_index "comments", ["user_id", "question_id"], :name => "idx_comments_on_user_id_and_question_id"
  end
end


