class AddGroupEvalFlag < ActiveRecord::Migration
  def change
    add_column :groups, :send_evaluation, :boolean, default: true

    # set australian groups to false
    Group.reset_column_information
    aus_groups =  Group.where("id in (#{Group::AUSTRALIAN_GROUPS.join(',')})")
    aus_groups.each do |g|
      g.update_column(:send_evaluation,false)
    end
    
  end
end
