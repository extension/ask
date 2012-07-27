class UserPreference < ActiveRecord::Base
  belongs_to :user
  
  AAE_LOCATION_ONLY = 'aae_location_only'
  AAE_COUNTY_ONLY = 'aae_county_only'
  FILTER_WIDGET_ID = 'filter.widget.id'
  AAE_FILTER_SOURCE = 'expert.source.filter'
  AAE_FILTER_CATEGORY = 'expert.category.filter'
  AAE_FILTER_COUNTY = 'expert.county.filter'
  AAE_FILTER_LOCATION = 'expert.location.filter'
  AAE_SIGNATURE = 'signature'
end
