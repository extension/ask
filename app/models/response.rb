# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Response < ActiveRecord::Base
  include MarkupScrubber
  belongs_to :question
  belongs_to :resolver, :class_name => "User", :foreign_key => "resolver_id"
  belongs_to :submitter, :class_name => "User", :foreign_key => "submitter_id"
  has_many :ratings
  has_many :images, :as => :assetable, :class_name => "Response::Image", :dependent => :destroy
  belongs_to :contributing_question, :class_name => "Question", :foreign_key => "contributing_question_id"
  
  accepts_nested_attributes_for :images, :allow_destroy => true
  
  after_save :check_first_response, :index_parent_question
  
  validates :body, :presence => true
  validate :validate_attachments
  
  # reporting scopes
  YEARWEEK_RESOLVED = 'YEARWEEK(responses.created_at,3)'

  def validate_attachments
    allowable_types = ['image/jpeg','image/png','image/gif','image/pjpeg','image/x-png']
    images.each {|i| self.errors[:base] << "Image is over 5MB" if i.attachment_file_size > 5.megabytes}
    images.each {|i| self.errors[:base] << "Image is not correct file type" if !allowable_types.include?(i.attachment_content_type)}
  end

  # attr_writer override for body to scrub html
  def body=(bodycontent)
    write_attribute(:body, self.cleanup_html(bodycontent))
  end
  
  class Response::Image < Asset
    has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :url => "/system/files/:class/:attachment/:id_partition/:basename_:style.:extension"
  end
  
  private

  def check_first_response
    if(self.question.initial_response_id.blank?)
      self.question.update_attributes({initial_response_id: self.id, initial_response_time: self.created_at - self.question.created_at})
    end
  end
  
  def index_parent_question
    Sunspot.index(self.question)
  end
    
end

