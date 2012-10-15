class UserPreference < ActiveRecord::Base
  belongs_to :user
  
  GROUP_ID_FILTER = 'group_id_filter'
  TAG_FILTER = 'tag_filter'
  COUNTY_FILTER = 'county_filter'
  LOCATION_FILTER = 'location_filter'
end

