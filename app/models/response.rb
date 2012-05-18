class Response < ActiveRecord::Base
  belongs_to :question
  belongs_to :resolver, :class_name => "User", :foreign_key => "resolver_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  has_many :ratings
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  
  accepts_nested_attributes_for :images
  
end

