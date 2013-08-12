class UserLocation < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  
  validates :user_id, :uniqueness => { :scope => :location_id }
end
