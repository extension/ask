class AddQuestionDataCache < ActiveRecord::Migration
  def change
    create_table "question_data_caches", :force => true do |t|
      t.integer  "question_id"
      t.text     "data_values"
      t.timestamps
    end

    add_index "question_data_caches", ["question_id"], :name => "question_ndx", :unique => true
  end

end
