class RemoveWidgetActiveSetting < ActiveRecord::Migration
  def change
    remove_column(:groups, :widget_active)
  end
end
