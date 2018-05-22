class CleanupDataItems < ActiveRecord::Migration
  def up
    drop_table(:ratings)
  end

  def down
  end
end
