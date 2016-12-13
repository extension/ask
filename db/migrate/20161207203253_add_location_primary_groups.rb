class AddLocationPrimaryGroups < ActiveRecord::Migration
  def change
    add_column(:group_locations, :is_primary, :boolean, default: false, null: false)
    add_column(:group_locations, :created_at, :datetime, null: false, default: Time.parse('2012-12-03'))
    add_column(:group_locations, :updated_at, :datetime, null: false, default: Time.parse('2012-12-03'))
    add_index "group_locations", ["is_primary"], :name => "primary_ndx"
  end
end
