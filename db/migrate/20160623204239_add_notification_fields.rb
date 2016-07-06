class AddNotificationFields < ActiveRecord::Migration
  def change
    add_column(:notifications, :process_on_create, :boolean, default: false)
    add_column(:notifications, :results, :text)
    remove_column(:notifications, :offset)
  end
end
