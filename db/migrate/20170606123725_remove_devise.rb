class RemoveDevise < ActiveRecord::Migration
  def up
    add_column(:users, :openid, :string, :null => true)
    add_column(:users, :institution_id, :integer, :null => true)
    add_column(:users, :last_activity_at, :datetime, :null => true)

    # set openid from authmaps
    execute "UPDATE users,authmaps set users.openid = authmaps.authname where authmaps.source = 'people' and authmaps.user_id = users.id"
    execute "UPDATE users set last_activity_at = current_sign_in_at where 1"

    drop_table(:authmaps)
    remove_column(:users, :encrypted_password)
    remove_column(:users, :remember_created_at)
    remove_column(:users, :sign_in_count)
    remove_column(:users, :current_sign_in_at)
    remove_column(:users, :last_sign_in_at)
    remove_column(:users, :current_sign_in_ip)
    remove_column(:users, :last_sign_in_ip)
  end

  def down
  end
end
