class GroupLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :group
  
  validates :group_id, :uniqueness => { :scope => :location_id }
end
