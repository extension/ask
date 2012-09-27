class Response < ActiveRecord::Base
  belongs_to :question
  belongs_to :resolver, :class_name => "User", :foreign_key => "resolver_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  has_many :ratings
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  
  accepts_nested_attributes_for :images
  
  before_create :calculate_duration_since_last, :clean_response
  after_save :index_parent_question
  
  def calculate_duration_since_last
    parent_question_id = self.question_id
    last_response = Response.find(:first, :conditions => {:question_id => parent_question_id}, :order => "created_at DESC")
    if last_response
      self.duration_since_last = Time.now - last_response.created_at
    else
      self.duration_since_last = 0
    end
  end
  
  #TODO: Need to Fill This In
  def clean_response
    return
  end
  
  class Response::Image < Asset
    has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  end
  
  private
  
  def index_parent_question
    Sunspot.index(self.question)
  end
    
end

