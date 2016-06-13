class CleanupGroupConnections < ActiveRecord::Migration
  def up
    remove_column(:group_connections,:connection_code)
    remove_column(:group_connections,:send_notifications)
    remove_column(:group_connections, :connected_by)

    # data cleanup
    execute("DELETE from group_connections WHERE connection_type NOT IN('leader','member')")
    execute("UPDATE group_connections SET created_at = '2012-12-03 12:04:00' where created_at < '2012-12-03 12:04:00'")

  end
end
