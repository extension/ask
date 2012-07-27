class GroupCounty < ActiveRecord::Base
  belongs_to :county
  belongs_to :group
end
