class Question < ActiveRecord::Base
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  belongs_to :assignee, :class_name => "User", :foreign_key => "assignee_id"
  belongs_to :current_resolver, :class_name => "User"
  belongs_to :location
  belongs_to :county
  belongs_to :widget
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  
  has_many :comments
  has_many :ratings
  has_many :responses
  has_many :question_events
  
  
  accepts_nested_attributes_for :images
end
