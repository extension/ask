class UserPreference < ActiveRecord::Base
  belongs_to :user
  
  serialize :setting
end

