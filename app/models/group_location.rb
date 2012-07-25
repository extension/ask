class GroupLocation < ActiveRecord::Base
  has_many :locations
  has_many :groups
end
