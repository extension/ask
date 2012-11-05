class FilterPreference < ActiveRecord::Base
  belongs_to :user
  
  serialize :setting
end

