class CleanupDataItems < ActiveRecord::Migration
  def up
    drop_table(:ratings)
    drop_table(:notification_exceptions)
  end

  def down
  end
end
