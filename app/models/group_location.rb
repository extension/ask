class GroupLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :group
end
