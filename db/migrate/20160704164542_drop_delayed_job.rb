class DropDelayedJob < ActiveRecord::Migration
  def up
    remove_column(:notifications, :delayed_job_id)
    drop_table(:delayed_jobs)
  end

  def down
  end
end
