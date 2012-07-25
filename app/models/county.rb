class County < ActiveRecord::Base
  has_many :user_counties
  has_many :users, :through => :user_counties
  belongs_to :location
    
end
