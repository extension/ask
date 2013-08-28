# set default values for group boolean columns including the widget_show_location column that was 
# causing some data issues by being null and not a boolean value. while we're at it, fix the 
# data for widget_show_location and other null columns that should have a default
class WidgetLocationOptionDataFix < ActiveRecord::Migration
  def change
    change_column :groups, :widget_upload_capable, :boolean, default: false
    change_column :groups, :widget_show_location, :boolean, default: false
    change_column :groups, :widget_show_title, :boolean, default: false
    change_column :groups, :widget_enable_tags, :boolean, default: false
    
    # fix existing data for show location on widget. when assignment_outside_locations is false, we show the location on the widget.
    # the application logic supports this, but there were a few groups that had null in the widget_show_location column where it was expecting a 
    # boolean therefore not setting it to true when the assignment_outside_location was changed to false.
    execute("UPDATE groups SET widget_show_location = 1 WHERE assignment_outside_locations = 0 AND widget_show_location IS NULL")
    
    # make sure all the columns that were null now have a false (0) in them
    execute("UPDATE groups SET widget_upload_capable = 0 WHERE widget_upload_capable IS NULL")
    execute("UPDATE groups SET widget_show_location = 0 WHERE widget_show_location IS NULL")
    execute("UPDATE groups SET widget_show_title = 0 WHERE widget_show_title IS NULL")
    execute("UPDATE groups SET widget_enable_tags = 0 WHERE widget_enable_tags IS NULL")
  end
end
