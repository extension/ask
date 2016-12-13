class DataCleanup < ActiveRecord::Migration
  def change
    remove_column(:group_events, :description)
    remove_column(:user_events, :description)
  end
end
