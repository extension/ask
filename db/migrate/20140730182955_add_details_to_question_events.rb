class AddDetailsToQuestionEvents < ActiveRecord::Migration
  def change
    add_column :question_events, :added_tag, :text
    add_column :question_events, :deleted_tag, :text
  end
end
