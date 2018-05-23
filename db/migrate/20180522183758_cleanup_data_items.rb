class CleanupDataItems < ActiveRecord::Migration
  def up
    drop_table(:ratings)
    drop_table(:notification_exceptions)
    remove_column(:mailer_caches, :open_count)
    drop_table(:comments)
    
  end

  def down
  end
end
