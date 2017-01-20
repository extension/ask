class LocationAlways < ActiveRecord::Migration
  def change
    rename_column(:groups, :widget_show_location, :unused_widget_show_location)
    remove_column(:groups, :ask_form_show_location)
  end

end
