# this column will deteremine if when a question comes into a group, whether the county associated with it (if it exists)
# will be used at all for auto-routing or if the routing will be load based, based on the location of the group assignees with
# the county being ignored.
class AddIgnoreCountyRoutingToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :ignore_county_routing, :boolean, :default => false
  end
end
