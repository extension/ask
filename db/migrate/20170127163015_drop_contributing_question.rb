class DropContributingQuestion < ActiveRecord::Migration
  def change
    remove_column(:questions, :contributing_question_id)
    remove_column(:question_events, :contributing_question_id)
    remove_column(:responses, :contributing_question_id)
  end

  def down
  end
end
