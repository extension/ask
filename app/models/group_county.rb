class GroupCounty < ActiveRecord::Base
  belongs_to :county
  belongs_to :group
  
  validates :group_id, :uniqueness => { :scope => :county_id }
end
