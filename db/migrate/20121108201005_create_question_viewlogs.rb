class CreateQuestionViewlogs < ActiveRecord::Migration
  def change
    create_table :question_viewlogs do |t|
      t.references :user, :null => false
      t.references :question
      t.integer    "activity"
      # intentionally not using t.references
      # so that we can limit the size of the type
      # and tighten the index
      t.integer    "view_count", default: 1, :null => false
      t.datetime   "updated_at"      
    end
    
    add_index("question_viewlogs", ["user_id", "question_id", "activity"], :unique => true, :name => "activity_uniq_ndx")
  end
end
