class AddAvailable < ActiveRecord::Migration
  def change
    rename_column(:users, :retired, :unavailable)
    remove_column(:users, :is_blocked)
    add_column(:users, :unavailable_reason, :integer)
    execute "UPDATE users SET unavailable_reason = #{User::UNAVAILABLE_RETIRED} where unavailable = 1"
  end
end
