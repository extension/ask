class LocationAlways < ActiveRecord::Migration
  def change
    remove_column(:groups, :widget_show_location)
    remove_column(:groups, :ask_form_show_location)
  end

end
