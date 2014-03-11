class AddExpertFlagToQuestionEvents < ActiveRecord::Migration
  def change
    add_column :question_events, :is_expert, :boolean, default: false, null: true
    execute "UPDATE question_events, users SET question_events.is_expert = 1 WHERE question_events.initiated_by_id = users.id and users.kind = 'User'"
  end
end
