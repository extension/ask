class AddNotificationIndex < ActiveRecord::Migration
  def change
    add_index "notifications", [:notifiable_type, :notifiable_id], :name => "notifiable_ndx"

  end

  def down
  end
end
