class AddLocationPrimaryGroups < ActiveRecord::Migration
  def change
    add_column(:group_locations, :is_primary, :boolean, default: false, null: false)
    add_column(:group_locations, :created_at, :datetime, null: false)
    add_column(:group_locations, :updated_at, :datetime, null: false)
    add_index "group_locations", ["is_primary"], :name => "primary_ndx"
    execute "UPDATE group_locations SET updated_at = NOW(),created_at=NOW()"
  end
end
