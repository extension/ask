class ChangeKindForSystemsAccounts < ActiveRecord::Migration
  def up
    # use active record for this so solr will update the indices
    systems_users = User.find(:all, conditions: "id IN (1,2,3,4,5,6)")
    systems_users.each do |su|
      su.update_attribute(:kind, "SystemsUser")
    end
  end

  def down
  end
end
