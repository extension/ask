class UserCounty < ActiveRecord::Base  
  belongs_to :user
  belongs_to :county
end
