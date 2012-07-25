class GroupCounty < ActiveRecord::Base
  has_many :groups
  has_many :counties
end
