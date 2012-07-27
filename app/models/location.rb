class Location < ActiveRecord::Base
  has_many :user_locations
  has_many :users, :through => :user_locations
  has_many :group_locations
  has_many :groups, :through => :group_locations
  has_many :counties
  
  
end
