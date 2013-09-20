class AddGroupActive < ActiveRecord::Migration
  def change
    # get more specific with existing column that denotes whether a group's widget is active or not
    rename_column :groups, :active, :widget_active
    add_column :groups, :group_active, :boolean, :null => false, :default => true
    
    # if group ain't got no one, inactivate the widget and the group.
    Group.all.each do |g|
      if g.joined.count == 0
        g.update_attributes(widget_active: false, group_active: false)
      end
    end
  end
end
