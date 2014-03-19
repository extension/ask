class AddQuestionFilter < ActiveRecord::Migration
  def change

    create_table "question_filters", :force => true do |t|
      t.integer  "created_by"
      t.text     "settings"
      t.string   "fingerprint", :limit => 40
      t.integer  "use_count"
      t.timestamps
    end

    add_index "question_filters", ["fingerprint"], :name => "fingerprint_ndx", :unique => true

  end
end
