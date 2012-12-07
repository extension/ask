class ExpandUserBio < ActiveRecord::Migration
  # doing the old school up and down migration here, b/c rails does not support this type of change 
  # on the change method
  def up
    change_column :users, :bio, :text
  end

  # not going to do a down for this
  def down
  end
end
