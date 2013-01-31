class TurnOnLocationOption < ActiveRecord::Migration
  # for existing groups that do not want questions assigned to them outside their locations, turn on the location option for their widgets, because
  # if not, all questions will fall outside their prefs and get bounced to the Question Wranglers
  def up 
    groups = Group.all
    change_hash = Hash.new
    
    groups.each do |g|
      if g.assignment_outside_locations == false && g.widget_show_location == false
        g.update_attribute(:widget_show_location, true)
        change_hash[:show_location] = {:old => false, :new => true}
        GroupEvent.log_edited_attributes(g, User.system_user, nil, change_hash)
      end
    end
  end
  
  def down
  end
end
