class GroupConnection < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  belongs_to :connector, :class_name => "User", :foreign_key => "connected_by"
end
