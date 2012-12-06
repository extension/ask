class AddLastActiveAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_active_at, :date
    execute "UPDATE users SET last_active_at = last_sign_in_at"
  end
end
