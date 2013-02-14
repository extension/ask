class FillInAllCounties < ActiveRecord::Migration
  # this is to cover the case of experts and groups who have added a state and no counties, but the 'all county' county was not added.
  def up
    # fill in all counties for experts
    experts = User.includes(:expertise_locations).where(kind: 'User').each do |u|
      expertise_locations = u.expertise_locations
      if expertise_locations.length > 0
        expertise_locations.each do |l|
          county_ids = l.counties.map(&:id).join(",")
          if UserCounty.where("user_id = #{u.id} AND county_id IN (#{county_ids})").count == 0
            UserCounty.create(user_id: u.id, county_id: l.get_all_county.id)
          end
        end
      end
    end
    
    groups = Group.includes(:expertise_locations).all.each do |g|
      expertise_locations = g.expertise_locations
      if expertise_locations.length > 0
        expertise_locations.each do |l|
          county_ids = l.counties.map(&:id).join(",")
          if GroupCounty.where("group_id = #{g.id} AND county_id IN (#{county_ids})").count == 0
            GroupCounty.create(group_id: g.id, county_id: l.get_all_county.id)
          end
        end
      end
    end
  end

  def down
  end
end
