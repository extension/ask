class AddUpdatedQuestionValues < ActiveRecord::Migration
  def change
    add_column :question_events, :updated_question_values, :text
  end
end
