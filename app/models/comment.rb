class Comment < ActiveRecord::Base
  belongs_to :question
  belongs_to :user
  has_many :ratings
  
  
end
