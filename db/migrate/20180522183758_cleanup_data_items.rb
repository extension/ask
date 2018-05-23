class CleanupDataItems < ActiveRecord::Migration
  def up
    drop_table('ratings')
    drop_table('notification_exceptions')
    remove_column(:mailer_caches, :open_count)
    drop_table('comments')
    drop_table('question_viewlogs')
    drop_table('activity_logs')
    drop_table('old_evaluation_answers')
  end

  def down
  end
end
