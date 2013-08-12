class UserCounty < ActiveRecord::Base  
  belongs_to :user
  belongs_to :county
  
  validates :user_id, :uniqueness => { :scope => :county_id }
end
