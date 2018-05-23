class CleanupDataItems < ActiveRecord::Migration
  def up
    drop_table('ratings')
    drop_table('notification_exceptions')
    remove_column(:mailer_caches, :open_count)
    drop_table('comments')
    drop_table('question_viewlogs')
    drop_table('activity_logs')
    drop_table('old_evaluation_answers')
    drop_table('demographic_logs')
    drop_table('evaluation_logs')

    drop_table('location_tracks')
    drop_table('ask_tracks')
    drop_table('referer_tracks')

  end

  def down
  end
end
